import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/partials/chat/message_composer/matrix_message_composer.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';

import '../utils/platform_infos.dart';

class MatrixStoriesPage extends StatefulWidget {
  const MatrixStoriesPage(this.room, {super.key});
  final Room room;

  static Future<void> show(BuildContext context, Room room) async {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => MatrixStoriesPage(room)));
  }

  @override
  MatrixStoriesPageState createState() => MatrixStoriesPageState();
}

class MatrixStoriesPageState extends State<MatrixStoriesPage> {
  final Duration _storieMaxDuration = const Duration(seconds: 3);
  final Duration _step = const Duration(milliseconds: 50);

  Timer? _timer;

  int index = 0;
  int max = 0;

  Timeline? timeline;

  final List<Event> events = [];
  final Map<String, Future<MatrixFile>> _fileCache = {};

  bool loadingMode = false;
  bool timerEnabled = true;

  Event? get currentEvent => index < events.length ? events[index] : null;
  StoryThemeData get storyThemeData =>
      StoryThemeData.fromJson(currentEvent?.content
              .tryGetMap<String, dynamic>(StoryThemeData.contentKey) ??
          {});

  Duration _progress = Duration.zero;
  void _timerCallback(Timer t) {
    if (!mounted) {
      t.cancel();
      return;
    }
    if (timerEnabled) {
      if (loadingMode || events.isEmpty) {
        _progress = Duration.zero;
      } else {
        setState(() {
          _progress += _step;
        });
      }

      if (_progress > _storieMaxDuration) {
        skip();
      }
    }
  }

  void _restartTimer([bool reset = true]) {
    _timer?.cancel();
    if (reset) _progress = Duration.zero;
    _timer = null;
  }

  bool get isOwnStory => widget.room.ownPowerLevel >= 100;

  void skip() {
    if (index + 1 >= max) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _timer?.cancel();
      return;
    }
    _restartTimer();
    setState(() {
      index++;
    });
    maybeSetReadMarker();
  }

  DateTime _holdedAt = DateTime.fromMicrosecondsSinceEpoch(0);
  bool isHold = false;

  void hold([_]) {
    _holdedAt = DateTime.now();
    if (loadingMode) return;
    _timer?.cancel();
    setState(() {
      isHold = true;
    });
    setState(() {});
  }

  void unhold([_]) {
    isHold = false;
    if (DateTime.now().millisecondsSinceEpoch -
            _holdedAt.millisecondsSinceEpoch <
        600) {
      skip();
      return;
    }
    _restartTimer(false);
    setState(() {});
  }

  Future<MatrixFile> downloadAndDecryptAttachment(
      Event event, bool getThumbnail) async {
    return _fileCache[event.eventId] ??=
        event.downloadAndDecryptAttachment(getThumbnail: getThumbnail);
  }

  Future<void>? loadStory;

  Future<void> _loadStory() async {
    final room = widget.room;
    try {
      final client = room.client;
      await client.roomsLoading;
      await client.accountDataLoading;
      if (room.membership != Membership.join) {
        final joinedFuture = room.client.onSync.stream
            .where((u) => u.rooms?.join?.containsKey(room.id) ?? false)
            .first;
        await room.join();
        await joinedFuture;
      }
      final timeline = this.timeline = await room.getTimeline();
      timeline.requestKeys();
      var events = timeline.events
          .where((e) =>
              e.type == EventTypes.Message &&
              !e.redacted &&
              e.status == EventStatus.synced)
          .toList();

      final hasOutdatedEvents = events.removeOutdatedEvents();

      // Request history if possible
      if (!hasOutdatedEvents &&
          timeline.events.first.type != EventTypes.RoomCreate &&
          events.length < 30) {
        try {
          await timeline
              .requestHistory(historyCount: 100)
              .timeout(const Duration(seconds: 5));
          events = timeline.events
              .where((e) => e.type == EventTypes.Message)
              .toList();
          events.removeOutdatedEvents();
        } catch (e, s) {
          Logs().d('Unable to request history in stories', e, s);
        }
      }

      max = events.length;
      if (events.isNotEmpty) {
        _restartTimer();
      }

      // Preload images and videos
      events
          .where((event) => {MessageTypes.Image, MessageTypes.Video}
              .contains(event.messageType))
          .forEach((event) => downloadAndDecryptAttachment(
              event,
              event.messageType == MessageTypes.Video &&
                  PlatformInfos.isMobile));

      // Reverse list
      this.events.clear();
      this.events.addAll(events.reversed.toList());

      // Set start position
      if (this.events.isNotEmpty) {
        final receiptId = room.roomAccountData['m.receipt']?.content
            .tryGetMap<String, dynamic>(room.client.userID!)
            ?.tryGet<String>('event_id');
        index = this.events.indexWhere((event) => event.eventId == receiptId);
        index++;
        if (index >= this.events.length) index = 0;
      }
      maybeSetReadMarker();
    } catch (e, s) {
      Logs().e('Unable to load story', e, s);
    }
    return;
  }

  List<User> get currentSeenByUsers {
    final timeline = this.timeline;
    final currentEvent = this.currentEvent;
    if (timeline == null || currentEvent == null) return [];
    return widget.room.getSeenByUsers(
      timeline,
      events,
      eventId: currentEvent.eventId,
    );
  }

  void maybeSetReadMarker() {
    final currentEvent = this.currentEvent;
    if (currentEvent == null) return;
    if (index == events.length - 1) {
      timeline!.setReadMarker();
      return;
    }
    if (!currentSeenByUsers.any((u) => u.id == u.room.client.userID)) {
      timeline!.setReadMarker(eventId: currentEvent.eventId);
    }
  }

  void _setLoadingMode(bool mode) => loadingMode != mode
      ? WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            loadingMode = mode;
          });
        })
      : null;
  void loadingModeOn() => _setLoadingMode(true);
  void loadingModeOff() => _setLoadingMode(false);

  static const List<Shadow> textShadows = [
    Shadow(
      color: Colors.black,
      offset: Offset(5, 5),
      blurRadius: 20,
    ),
    Shadow(
      color: Colors.black,
      offset: Offset(5, 5),
      blurRadius: 20,
    ),
    Shadow(
      color: Colors.black,
      offset: Offset(-5, -5),
      blurRadius: 20,
    ),
    Shadow(
      color: Colors.black,
      offset: Offset(-5, -5),
      blurRadius: 20,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    _timer ??= Timer.periodic(_step, _timerCallback);
    loadStory ??= _loadStory();

    Client c = widget.room.client;

    if (widget.room.lastEvent == null) const Text("No data");

    return FutureBuilder(
        future: loadStory,
        builder: (context, snapshot) {
          final error = snapshot.error;
          if (error != null) {
            return Scaffold(
                appBar: AppBar(
                    title: const Text("Snap! Something unexpected happened")),
                body: Center(child: Text(error.toString())));
          }

          if (events.isEmpty ||
              snapshot.connectionState != ConnectionState.done) {
            return Scaffold(
              appBar: AppBar(title: const Text("Story")),
              body: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MatrixImageAvatar(
                      height: 128,
                      width: 128,
                      client: widget.room.client,
                      defaultText: widget.room.creator?.calcDisplayname(),
                      url: widget.room.creator?.avatarUrl,
                    ),
                    const SizedBox(height: 32),
                    snapshot.connectionState != ConnectionState.done
                        ? const CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          )
                        : const Text(
                            "This user hasn't sent any stories yet",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                  ],
                ),
              ),
            );
          }

          final event = events[index];
          final backgroundColor = storyThemeData.color1 ??
              event.content.tryGet<String>('body')?.color ??
              Theme.of(context).colorScheme.primary;
          final backgroundColorDark = storyThemeData.color2 ??
              event.content.tryGet<String>('body')?.darkColor ??
              Theme.of(context).colorScheme.primary;
          if (event.messageType == MessageTypes.Text) {
            loadingModeOff();
          }
          final hash = event.infoMap['xyz.amorgan.blurhash'];

          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: event.messageType == MessageTypes.Text
                    ? LinearGradient(
                        colors: [
                          backgroundColorDark,
                          backgroundColor,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
              ),
              child: GestureDetector(
                onTapDown: hold,
                onTapUp: unhold,
                onTapCancel: unhold,
                onVerticalDragStart: hold,
                onVerticalDragEnd: unhold,
                onHorizontalDragStart: hold,
                onHorizontalDragEnd: unhold,
                child: Stack(
                  children: [
                    if (hash is String)
                      BlurHash(
                        hash: hash,
                        imageFit: BoxFit.cover,
                      ),
                    SafeArea(
                      child: Stack(
                        children: [
                          if (event.messageType == MessageTypes.Image)
                            FutureBuilder<MatrixFile>(
                                future:
                                    downloadAndDecryptAttachment(event, false),
                                builder: (context, fileSnap) {
                                  final matrixFile = fileSnap.data;
                                  if (matrixFile == null) {
                                    loadingModeOn();
                                    return Container();
                                  }
                                  loadingModeOff();
                                  return Container(
                                    constraints: const BoxConstraints.expand(),
                                    alignment:
                                        storyThemeData.fit == BoxFit.cover
                                            ? null
                                            : Alignment.center,
                                    child: Image.memory(
                                      matrixFile.bytes,
                                      fit: storyThemeData.fit,
                                    ),
                                  );
                                }),
                          Container(
                            alignment: Alignment(
                              storyThemeData.alignmentX.toDouble() / 100,
                              storyThemeData.alignmentY.toDouble() / 100,
                            ),
                            child: Text(
                              event.text,
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                shadows: event.messageType == MessageTypes.Text
                                    ? null
                                    : textShadows,
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              ListTile(
                                leading: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                title: Text(widget.room
                                        .getState(EventTypes.RoomCreate)
                                        ?.senderFromMemoryOrFallback
                                        .calcDisplayname() ??
                                    'Story not found'),
                              ),
                              Row(
                                children: [
                                  for (final e in events)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(2),
                                        child: LinearProgressIndicator(
                                            value: e == event
                                                ? !loadingMode
                                                    ? _progress.inMilliseconds /
                                                        _storieMaxDuration
                                                            .inMilliseconds
                                                    : null
                                                : 0),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          if (event.senderId !=
                              c.userID) // don't allow sending message to the actual user
                            Positioned(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 800),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2.0, horizontal: 4),
                                        child: MatrixMessageComposer(
                                            client: event.room.client,
                                            room: event.room,
                                            onReplyTo: event,
                                            hintText: "Reply",
                                            allowSendingPictures: false,
                                            enableAutoFocusOnDesktop: false,
                                            overrideSending:
                                                (String text) async {
                                              String roomId =
                                                  await c.startDirectChat(
                                                      event.senderId);
                                              Room? r = c.getRoomById(roomId);
                                              await r?.sendTextEvent(text);
                                            },
                                            onEdit: (val) {
                                              setState(() {
                                                timerEnabled = val == "";
                                              });
                                            },
                                            onSend: () {
                                              setState(() {
                                                timerEnabled = true;
                                              });
                                            }),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

extension on List<Event> {
  bool removeOutdatedEvents() {
    final outdatedIndex = indexWhere((event) =>
        DateTime.now().difference(event.originServerTs).inHours >
        StoriesExtension.lifeTimeInHours);
    if (outdatedIndex != -1) {
      removeRange(outdatedIndex, length);
      return true;
    }
    return false;
  }
}

extension on Room {
  List<User> getSeenByUsers(Timeline timeline, List<Event> filteredEvents,
      {String? eventId}) {
    if (timeline.events.isEmpty) return [];

    final filteredEvents =
        timeline.events.where((event) => event.messageType != "");
    if (filteredEvents.isEmpty) return [];
    eventId ??= filteredEvents.first.eventId;

    final lastReceipts = <User>{};
    // now we iterate the timeline events until we hit the first rendered event
    for (final event in timeline.events) {
      lastReceipts.addAll(event.receipts.map((r) => r.user));
      if (event.eventId == eventId) {
        break;
      }
    }
    lastReceipts.removeWhere((user) =>
        user.id == client.userID || user.id == filteredEvents.first.senderId);
    return lastReceipts.toList();
  }
}

class StoryThemeData {
  final Color? color1;
  final Color? color2;
  final BoxFit fit;
  final int alignmentX;
  final int alignmentY;

  static const String contentKey = 'msc3588.stories.design';

  const StoryThemeData({
    this.color1,
    this.color2,
    this.fit = BoxFit.contain,
    this.alignmentX = 0,
    this.alignmentY = 0,
  });

  factory StoryThemeData.fromJson(Map<String, dynamic> json) {
    final color1Int = json.tryGet<int>('color1');
    final color2Int = json.tryGet<int>('color2');
    final color1 = color1Int == null ? null : Color(color1Int);
    final color2 = color2Int == null ? null : Color(color2Int);
    return StoryThemeData(
      color1: color1,
      color2: color2,
      fit:
          json.tryGet<String>('fit') == 'cover' ? BoxFit.cover : BoxFit.contain,
      alignmentX: json.tryGet<int>('alignment_x') ?? 0,
      alignmentY: json.tryGet<int>('alignment_y') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        if (color1 != null) 'color1': color1?.value,
        if (color2 != null) 'color2': color2?.value,
        'fit': fit.name,
        'alignment_x': alignmentX,
        'alignment_y': alignmentY,
      };
}

extension StringColor on String {
  Color get color {
    var number = 0.0;
    for (var i = 0; i < length; i++) {
      number += codeUnitAt(i);
    }
    number = (number % 12) * 25.5;
    return HSLColor.fromAHSL(1, number, 1, 0.35).toColor();
  }

  Color get darkColor {
    var number = 0.0;
    for (var i = 0; i < length; i++) {
      number += codeUnitAt(i);
    }
    number = (number % 12) * 25.5;
    return HSLColor.fromAHSL(1, number, 1, 0.2).toColor();
  }

  Color get lightColor {
    var number = 0.0;
    for (var i = 0; i < length; i++) {
      number += codeUnitAt(i);
    }
    number = (number % 12) * 25.5;
    return HSLColor.fromAHSL(1, number, 1, 0.8).toColor();
  }
}
