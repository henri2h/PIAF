import 'dart:async';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/chat/message_composer/advanced_message_composer.dart';
import 'package:piaf/partials/matrix/matrix_image_avatar.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

import '../../utils/matrix_widget.dart';
import '../typing_indicator.dart';
import 'room_event_item.dart';

class RoomTimeline extends StatefulWidget {
  final Room? room;
  final String? userId;
  final Timeline? timeline;
  final Function(bool) setUpdating;
  final bool disableTimelinePadding;
  final bool isMobile;

  final void Function(Room)? onRoomCreate;

  final bool updating;
  final Stream<int> streamTimelineRemove;
  final Stream<int> streamTimelineInsert;

  const RoomTimeline(
      {super.key,
      required this.room,
      required this.isMobile,
      this.userId,
      this.disableTimelinePadding = false,
      this.onRoomCreate,
      required this.timeline,
      required this.updating,
      required this.setUpdating,
      required this.streamTimelineRemove,
      required this.streamTimelineInsert});

  @override
  RoomTimelineState createState() => RoomTimelineState();
}

class RoomTimelineState extends State<RoomTimeline> {
  static const double bottomPadding = 60;

  late String? initialFullyReadEventId;
  String? fullyReadEventId;
  StreamController<String> eventsToAnimate = StreamController.broadcast();

  Event? composerReplyToEvent;
  Room? room;
  List<Event> filteredEvents = [];

  Future<void>? request;

  // scrolling logic
  final _scrollController = ScrollController(
    initialScrollOffset: -bottomPadding,
  );
  // initial scroll offset due to list padding

  late ListObserverController observerController;
  late ChatScrollObserver chatObserver;

  late StreamSubscription<int>? onInsert;
  late StreamSubscription<int>? onRemove;

  late bool isDirectChat;

  @override
  void initState() {
    super.initState();
    room = widget.room ?? widget.timeline?.room;

    initialFullyReadEventId = room?.fullyRead;
    fullyReadEventId = initialFullyReadEventId;

    observerController = ListObserverController(controller: _scrollController)
      ..cacheJumpIndexOffset = false;

    /// Initialize ChatScrollObserver
    chatObserver = ChatScrollObserver(observerController)
      // Greater than this offset will be fixed to the current chat position.
      ..fixedPositionOffset = 1
      ..toRebuildScrollViewCallback = () {
        // Here you can use other way to rebuild the specified listView instead of [setState]
        setState(() {});
      }
      ..onHandlePositionResultCallback = (result) {
        switch (result.type) {
          case ChatScrollObserverHandlePositionType.keepPosition:
            // Keep the current chat position.
            // updateUnreadMsgCount(changeCount: result.changeCount);
            break;
          case ChatScrollObserverHandlePositionType.none:
            // Do nothing about the chat position.
            // updateUnreadMsgCount(isReset: true);
            break;
        }
      };

    _scrollController.addListener(scrollListener);

    // Update the chat observer
    onInsert = widget.streamTimelineInsert.listen((i) {
      if (i == 0) {
        // Don't move the chat list up because new element is added to the bottom
        chatObserver.standby();
      } else {
        chatObserver.standby(mode: ChatScrollObserverHandleMode.generative);
      }
    });
    onRemove = widget.streamTimelineRemove.listen((i) {
      chatObserver.standby(isRemove: true);
    });

    isDirectChat = room?.isDirectChat ?? false;
  }

  @override
  void deactivate() {
    super.deactivate();
    _scrollController.removeListener(scrollListener);
    onInsert?.cancel();
    onRemove?.cancel();
  }

  bool get hasScrollReachedBottom =>
      _scrollController.hasClients &&
      _scrollController.position.pixels -
              _scrollController.position.minScrollExtent <
          10;

  void scrollListener() async {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 600) {
      if (widget.updating == false &&
          (widget.timeline?.canRequestHistory ?? false)) {
        widget.setUpdating(true);
        await widget.timeline?.requestHistory();
        widget.setUpdating(false);
      }
    }
  }

  Future<void> requestHistoryIfNeeded() async {
    while ((widget.timeline?.canRequestHistory ?? false) &&
        _scrollController.hasClients &&
        _scrollController.position.hasContentDimensions &&
        _scrollController.position.maxScrollExtent == 0) {
      if (widget.timeline?.isRequestingHistory ?? false) {
        Future.delayed(const Duration(milliseconds: 200));
      } else {
        await widget.timeline?.requestHistory();
      }
    }
  }

  bool init = false;

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;

    if (!init) {
      if (widget.timeline?.events.isNotEmpty == true && room != null) {
        init = true;
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (room != null) markLastRead(room: room!);
        });
      }
    }

    if (request == null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (_scrollController.hasClients &&
            _scrollController.position.hasContentDimensions &&
            widget.timeline != null) {
          request ??= requestHistoryIfNeeded();
        }
      });
    }

    filteredEvents.clear();
    filteredEvents.addAll(filter(widget.timeline?.events) ?? []);

    return Column(
      children: [
        Expanded(
          child: Stack(children: [
            room != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ListViewObserver(
                      controller: observerController,
                      onObserve: (resultModel) {
                        int index = resultModel.firstChild?.index ?? 0;
                        _lastEventVisible = filteredEvents[index];
                      },
                      child: ListView.builder(
                          controller: _scrollController,
                          physics: ChatObserverClampingScrollPhysics(
                              observer: chatObserver),
                          reverse: true,
                          cacheExtent: 1000,
                          itemCount: filteredEvents.length,
                          itemBuilder: (BuildContext context, int index) {
                            return RoomEventItem(
                              key: Key("item_${filteredEvents[index].eventId}"),
                              room: room!,
                              // Calculating isDirectChat takes a lot of CPU time so
                              // we need to optimize it's usage
                              isDirectChat: isDirectChat,
                              filteredEvents: filteredEvents,
                              t: widget.timeline,
                              i: index,
                              onReplyEventPressed: (event) async {
                                // Jump to index
                                final index = filteredEvents.indexOf(
                                    event.getDisplayEvent(widget.timeline!));
                                if (index != -1) {
                                  eventsToAnimate.add(event.eventId);
                                  await observerController.animateTo(
                                      index: index,
                                      alignment: 0,
                                      duration:
                                          const Duration(milliseconds: 250),
                                      curve: Curves.ease);
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "Could not scroll to index, item not found")));
                                  }
                                }
                              },
                              eventsToAnimateStream: eventsToAnimate.stream,
                              onReply: (Event event) => setState(() {
                                composerReplyToEvent = event;
                              }),
                              fullyReadEventId: initialFullyReadEventId,
                            );
                          }),
                    ),
                  )
                : widget.userId?.startsWith("@") == true // Is a user
                    ? FutureBuilder<Profile>(
                        future: client.getProfileFromUserId(widget.userId!),
                        builder: (context, snap) {
                          return Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MatrixImageAvatar(
                                  url: snap.data?.avatarUrl,
                                  client: client,
                                  height: MinestrixAvatarSizeConstants.big,
                                  width: MinestrixAvatarSizeConstants.big,
                                  shape: MatrixImageAvatarShape.rounded,
                                  defaultText: snap.data?.displayName,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Expanded(
                                    child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 34),
                                  child: ListTile(
                                    title: Text(
                                        snap.data?.displayName ??
                                            widget.userId!,
                                        style: const TextStyle(fontSize: 24)),
                                    subtitle: Text(widget.userId!,
                                        style: const TextStyle(fontSize: 18)),
                                  ),
                                )),
                              ],
                            ),
                          );
                        })
                    : const Center(child: Text("An error happened")),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (User user in room?.typingUsers ?? [])
                  TypingIndicator(room: room!, user: user),
              ],
            )
          ]),
        ),
        AdvancedMessageComposer(
            room: room,
            isMobile: widget.isMobile,
            userId: widget.userId,
            client: client,
            onRoomCreate: widget.onRoomCreate,
            reply: composerReplyToEvent,
            removeReply: () {
              setState(() {
                composerReplyToEvent = null;
              });
            }),
      ],
    );
  }

  List<Event>? filter(List<Event>? events) => events
      ?.where((e) =>
          !{RelationshipTypes.edit, RelationshipTypes.reaction}
              .contains(e.relationshipType) &&
          !{
            EventTypes.Reaction,
            EventTypes.Redaction,
            EventTypes.CallCandidates,
            EventTypes.CallHangup,
            EventTypes.CallReject,
            EventTypes.CallNegotiate,
            EventTypes.CallAnswer,
            "m.call.select_answer",
            "org.matrix.call.sdp_stream_metadata_changed"
          }.contains(e.type))
      .toList();

  Event? _lastEventVisible;

  /// send a read event if we have read the last event
  Future<bool> markLastRead({required Room room}) async {
    // Only update the read marker if the user is in the room.
    // Room marker can't be updated if we are peeking the room
    if (room.membership != Membership.join) return false;

    if (widget.timeline?.events.isNotEmpty != true) return false;

    Event? lastVisibleEvent;

    // get last read item
    if (hasScrollReachedBottom) {
      lastVisibleEvent = widget.timeline?.events.first;

      // We need to set the last view marker at the last event
      if (room.hasNewMessages) {
        final lastEvent = room.lastEvent ?? lastVisibleEvent;
        if (lastEvent != null) {
          await room.setReadMarker(lastEvent.eventId, mRead: lastEvent.eventId);

          if (lastVisibleEvent?.eventId != null) {
            fullyReadEventId = lastVisibleEvent?.eventId;
          }
          return true;
        }
      }
    } else {
      lastVisibleEvent = _lastEventVisible;
    }

    if (lastVisibleEvent != null &&
        fullyReadEventId != lastVisibleEvent.eventId &&
        lastVisibleEvent.status.isSent) {
      final lastReadPos = widget.timeline!.events
          .indexWhere((element) => element.eventId == fullyReadEventId);
      final pos = widget.timeline!.events.indexOf(lastVisibleEvent);

      if (lastReadPos != -1 && pos >= lastReadPos) return false;

      final evId = lastVisibleEvent.eventId;
      await room.setReadMarker(evId, mRead: evId);

      fullyReadEventId = evId;
      return true;
    }
    return false;
  }
}
