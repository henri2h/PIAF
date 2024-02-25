library minestrix_chat;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/chat/partials/chat/room/room_timeline.dart';
import 'package:piaf/chat/partials/chat/room/room_title.dart';
import 'package:piaf/chat/utils/extensions/matrix/peeking_extension.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../../chat/partials/chat/settings/conv_settings.dart';
import '../chat_lib/room_settings_page.dart';

@RoutePage()
class RoomPage extends StatefulWidget {
  const RoomPage(
      {super.key,
      required this.roomId,
      required this.client,
      this.onBack,
      this.allowPop = false,
      this.displaySettingsOnDesktop = false});

  final String roomId;
  final Client client;
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
          areas: [Area(minimalSize: 400), Area(minimalSize: 200, size: 340)]);

  final streamTimelineInsert = StreamController<int>();
  final streamTimelineRemove = StreamController<int>();

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

    room = widget.client.getRoomById(widget.roomId);

    if (room != null) {
      futureTimeline = getTimeline(room!);
    } else if (widget.roomId.startsWith("!")) {
      // create room and timeline
      futureTimeline = peekRoom();
    }
  }

  Future<Timeline> peekRoom() async {
    try {
      final timeline = await widget.client.peekRoom(widget.roomId);
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

  Widget buildChatView(Room? room) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth < 600;
      final view = Column(
        children: [
          MatrixRoomTitle(
              height: 52,
              key: Key(room?.id ?? ""),
              room: room,
              client: widget.client,
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
            key: Key("room_timeline_$roomId"),
            isMobile: isMobile,
            room: room,
            userId: room?.id ?? widget.roomId,
            client: widget.client,
            timeline: timeline,
            updating: updating,
            streamTimelineRemove: streamTimelineRemove.stream,
            streamTimelineInsert: streamTimelineInsert.stream,
            onRoomCreate: (Room room) {
              timeline = null;
              futureTimeline = getTimeline(room);
              this.room = room;

              setState(() {
                roomId = room.id;
              });
            },
            setUpdating: (val) => mounted
                ? setState(() {
                    updating = val;
                  })
                : () {},
          )),
        ],
      );

      if (isMobile) return view;

      return MultiSplitViewTheme(
          data: MultiSplitViewThemeData(
              dividerPainter: DividerPainters.grooved1(
                  color: Colors.indigo[100]!,
                  highlightedColor: Colors.indigo[900]!)),
          child: MultiSplitView(
            controller: _controller,
            children: [
              Card(child: view),
              if (_displayConvSettings && room != null)
                Card(
                  child: ConvSettings(
                      room: room,
                      onClose: () => setState(() {
                            _displayConvSettings = false;
                          })),
                )
            ],
          ));
    });
  }
}
