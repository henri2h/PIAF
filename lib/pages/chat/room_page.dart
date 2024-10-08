library minestrix_chat;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/chat/room/room_timeline.dart';
import 'package:piaf/partials/chat/room/room_title.dart';
import 'package:piaf/partials/utils/extensions/matrix/peeking_extension.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../../partials/chat/settings/conv_settings.dart';
import '../../partials/utils/matrix_widget.dart';
import 'chat_lib/room_settings_page.dart';

@RoutePage()
class RoomPage extends StatefulWidget {
  const RoomPage(
      {super.key,
      required this.roomId,
      this.onBack,
      this.allowPop = true,
      this.displaySettingsOnDesktop = false});

  final String roomId;
  final void Function()? onBack;
  final bool allowPop;
  final bool displaySettingsOnDesktop;

  @override
  RoomPageState createState() => RoomPageState();
}

class RoomPageState extends State<RoomPage> {
  Future<Timeline>? futureTimeline;

// Perf: MultiSplitViewController constructor takes some time. When not needed, let's
// avoid building it.
  MultiSplitViewController? _cachedController;
  MultiSplitViewController get _controller =>
      _cachedController ??= MultiSplitViewController(
          areas: [Area(min: 400), Area(min: 200, size: 340)]);

  final streamTimelineInsert = StreamController<int>.broadcast();
  final streamTimelineRemove = StreamController<int>.broadcast();

  Room? room;

  late String roomId;

  int reloadedCount = 0;
  int roomUpdate = 0;

  Timeline? timeline;

  bool _displayConvSettings = true;

  bool updating = false;

  @override
  void initState() {
    super.initState();

    // init variables
    roomId = widget.roomId;
    _displayConvSettings = widget.displaySettingsOnDesktop;

    init();
  }

  void init() {
    timeline = null;
    final client = Matrix.of(context).client;

    room = client.getRoomById(widget.roomId);

    if (room != null) {
      futureTimeline = getTimeline(room!);
    } else if (widget.roomId.startsWith("!")) {
      // create room and timeline
      futureTimeline = peekRoom();
    }
  }

  Future<Timeline> peekRoom() async {
    final client = Matrix.of(context).client;
    try {
      final timeline = await client.peekRoom(widget.roomId);
      // update local variables
      room = timeline.room;
      this.timeline = timeline;

      return timeline;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
      rethrow;
    }
  }

  Future getImage() async {
    ImagePicker pick = ImagePicker();
    final pickedFile = await pick.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      Logs().i(pickedFile.path);
    } else {
      Logs().i('No image selected.');
    }
  }

  Future<Timeline> getTimeline(Room room) async {
    return await room.getTimeline(onInsert: (i) {
      if (mounted) {
        streamTimelineInsert.add(i);
        setState(() {
          roomUpdate++;
        });
      }
    }, onRemove: (i) {
      if (mounted) {
        streamTimelineRemove.add(i);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    reloadedCount++;

    if (room != null) {
      return FutureBuilder<Timeline?>(
        future: futureTimeline,
        builder: (BuildContext context, AsyncSnapshot<Timeline?> snapshot) {
          if (snapshot.hasData == false) {
            return Scaffold(
                appBar: AppBar(),
                body: Center(
                    child: snapshot.hasError
                        ? ListTile(
                            title: const Text("Could not load the room."),
                            subtitle: Text(snapshot.error.toString()))
                        : const CircularProgressIndicator()));
          }

          return StreamBuilder(
              stream: room?.onUpdate.stream,
              builder: (context, snap) {
                timeline = snapshot.data;
                return buildChatView(room);
              });
        },
      );
    }

    // If the room id is a valid user matrix id
    // then, we display the chat view in order to
    // allow creating a message
    if (widget.roomId.isValidMatrixId) {
      return buildChatView(room);
    }

    return Scaffold(
      appBar: AppBar(),
      body: const Text("Room not found"),
    );
  }

  void onRoomCreated(Room room) {
    timeline = null;
    futureTimeline = getTimeline(room);
    this.room = room;

    setState(() {
      roomId = room.id;
    });
  }

// Global key to prevent the room timeline from beeing rebuilt when
// the RoomTimeline's depth changes
  final roomTimelineKey = GlobalKey();

  Widget buildChatView(Room? room) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth < 600;
      bool isTablet = !isMobile && constraints.maxWidth < 800;
      bool isDesktop = !isTablet && !isMobile;

      // Display the conv settings pannel by default on desktop
      // hide it by default on tablet
      // never show it on mobile
      bool displayView = room == null ||
          isMobile ||
          (isTablet && _displayConvSettings) ||
          (isDesktop && !_displayConvSettings);

      final view = Column(
        children: [
          MatrixRoomTitle(
              height: 52,
              key: Key(room?.id ?? ""),
              room: room,
              userId: widget.roomId,
              updating: updating,
              onBack: widget.onBack ??
                  (widget.allowPop ? () => Navigator.of(context).pop() : null),
              onToggleSettings: () async {
                if (isMobile) {
                  await RoomSettingsPage.show(context: context, room: room!);
                } else {
                  setState(() {
                    _displayConvSettings = !_displayConvSettings;
                  });
                }
              }),
          Expanded(
              child: RoomTimeline(
            key: roomTimelineKey, // Key("room_timeline_$roomId"),
            isMobile: isMobile,
            room: room,
            userId: room?.id ?? widget.roomId,
            timeline: timeline,
            updating: updating,
            streamTimelineRemove: streamTimelineRemove.stream,
            streamTimelineInsert: streamTimelineInsert.stream,
            onRoomCreate: onRoomCreated,
            setUpdating: (val) => mounted
                ? setState(() {
                    updating = val;
                  })
                : () {},
          )),
        ],
      );

      if (displayView) return view;

      return MultiSplitViewTheme(
          data: MultiSplitViewThemeData(
              dividerPainter: DividerPainters.grooved1(
                  color: Colors.indigo[100]!,
                  highlightedColor: Colors.indigo[900]!)),
          child: MultiSplitView(
            controller: _controller,
            builder: ((context, area) {
              if (area.index == 0) return Card(child: view);
              if (area.index == 1) {
                return Card(
                  child: ConvSettings(
                      room: room,
                      onClose: () => setState(() {
                            _displayConvSettings != _displayConvSettings;
                          })),
                );
              }
              return Container();
            }),
          ));
    });
  }
}
