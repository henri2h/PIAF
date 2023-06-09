library minestrix_chat;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/chat/room/room_title.dart';
import 'package:minestrix_chat/partials/chat/room/room_timeline.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../partials/chat/room/room_search.dart';
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
  bool isSearch = false;

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
      final view = Stack(
        children: [
          Builder(builder: (context) {
            final roomTimeline = isSearch && room != null
                ? RoomSearch(
                    room: room,
                    onClosePressed: () {
                      setState(() {
                        isSearch = false;
                      });
                    },
                  )
                : RoomTimeline(
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
                  );
            if (isMobile) {
              return roomTimeline;
            }
            return Card(
                child: Padding(
              padding: const EdgeInsets.only(top: 52),
              child: roomTimeline,
            ));
          }),
          Builder(builder: (context) {
            final roomTitle = MatrixRoomTitle(
                height: 52,
                key: Key(room?.id ?? ""),
                room: room,
                client: widget.client,
                userId: widget.roomId,
                updating: updating,
                isMobile: isMobile,
                onBack: widget.onBack ??
                    (widget.allowPop
                        ? () => Navigator.of(context).pop()
                        : null),
                onSearchPressed: () {
                  setState(() {
                    isSearch = true;
                  });
                },
                onToggleSettings: () async {
                  if (isMobile) {
                    await RoomSettingsPage.show(context: context, room: room!);
                  } else {
                    setState(() {
                      _displayConvSettings = !_displayConvSettings;
                    });
                  }
                });

            return isMobile
                ? Container(
                    color: Theme.of(context)
                        .scaffoldBackgroundColor
                        .withAlpha(180),
                    child: ClipRRect(
                      key: const Key("room_title"),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: roomTitle,
                        ),
                      ),
                    ),
                  )
                : Container(child: roomTitle);
          }),
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
              view,
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
