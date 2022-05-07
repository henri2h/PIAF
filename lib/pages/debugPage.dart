import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/layouts/customHeader.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';

class DebugPage extends StatefulWidget {
  @override
  _DebugPageState createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  Future<void> loadElements(BuildContext context, Room room) async {
    setState(() {
      progressing = true;
    });

    Timeline? t = await room.getTimeline();

    await t.requestHistory();

    setState(() {
      progressing = false;
    });
  }

  List<int> timelineLength = [];
  List<Room> rooms = [];
  Client? client;
  bool init = false;

  bool progressing = false;
  @override
  Widget build(BuildContext context) {
    client = Matrix.of(context).client;

    rooms = client!.srooms;
    if (init == false) {
      init = true;
    }

    return ListView(children: [
      CustomHeader(title: "Debug"),
      H2Title("Minestrix rooms"),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Text("This is where the posts are stored."),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rooms.length != 0)
              for (var i = 0; i < rooms.length; i++)
                ListTile(
                    title: Text(rooms[i].name),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person, size: 16),
                              SizedBox(width: 10),
                              Text((rooms[i].creator?.displayName ??
                                  rooms[i].creatorId ??
                                  "null")),
                            ],
                          ),
                          Text(rooms[i].id),
                        ],
                      ),
                    ),
                    leading: (timelineLength.length > i)
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(timelineLength[i].toString()),
                          )
                        : null,
                    trailing: IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: () async {
                          await loadElements(context, rooms[i]);
                        })),
            if (client != null)
              Text("MinesTRIX rooms length : " +
                  client!.sroomsByUserId.length.toString()),
            if (progressing) CircularProgressIndicator(),
          ],
        ),
      ),
    ]);
  }
}
