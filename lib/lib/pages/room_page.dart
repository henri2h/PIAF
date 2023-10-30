library minestrix_chat;

import 'package:matrix/src/models/timeline_chunk.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/chat/room/room_timeline.dart';
import 'package:minestrix_chat/partials/chat/room/room_title.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../partials/chat/settings/conv_settings.dart';
import 'room_settings_page.dart';

class RoomPage extends StatefulWidget {
  const RoomPage(
      {Key? key,
      required this.roomId,
      required this.client,
      this.onBack,
      this.allowPop = false,
      this.displaySettingsOnDesktop = false})
      : super(key: key);

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
  final MultiSplitViewController _controller = MultiSplitViewController(
      areas: [Area(minimalSize: 400), Area(minimalSize: 200, size: 340)]);
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

    if (widget.roomId.startsWith("!")) {
      room = Room(id: widget.roomId, client: widget.client);
    }

    if (room != null) {
      futureTimeline = getTimeline(room!);
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
    if (room.prev_batch == null) {
      final res = await room.client.getRoomEvents(room.id, Direction.b);

      final timeline = Timeline(
          room: room,
          chunk: TimelineChunk(
              events: res.chunk.reversed
                  .toList() // we display the event in the other sence
                  .map((e) => Event.fromMatrixEvent(e, room))
                  .toList()));

      room.prev_batch = res.end;

      // Apply states
      res.state?.forEach((event) {
        room.setState(Event.fromMatrixEvent(
          event,
          room,
        ));
      });

      for (var event in res.chunk) {
        room.setState(Event.fromMatrixEvent(
          event,
          room,
        ));
      }

      return timeline;
    }

    return await room.getTimeline(onInsert: (i) {
      if (mounted) {
        setState(() {
          roomUpdate++;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    reloadedCount++;

    final chatView = FutureBuilder<Timeline?>(
      future: futureTimeline,
      builder: (BuildContext context, AsyncSnapshot<Timeline?> snapshot) {
        timeline = snapshot.data;

        return StreamBuilder(
            stream: room?.onUpdate.stream,
            builder: (context, snap) {
              return buildChatView(room);
            });
      },
    );

    if (room != null || widget.roomId.isValidMatrixId) {
      return chatView;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            icon: const Icon(Icons.navigate_before),
            onPressed: widget.onBack ??
                () {
                  Navigator.of(context).pop();
                }),
        const SizedBox(width: 8),
        const Text("Room not found"),
      ],
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
