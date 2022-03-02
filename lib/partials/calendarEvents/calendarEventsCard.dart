import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';

class CalendarEventCard extends StatefulWidget {
  final Room room;
  const CalendarEventCard({Key? key, required this.room}) : super(key: key);

  @override
  State<CalendarEventCard> createState() => _CalendarEventCardState();
}

class _CalendarEventCardState extends State<CalendarEventCard> {
  Future<void>? getState;
  @override
  void initState() {
    super.initState();
    getState = widget.room.postLoad();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getState,
        builder: (context, snapshot) {
          return Card(
            child: ListTile(
                title: Text(
                  widget.room.name,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.room.topic,
                      maxLines: 4,
                    ),
                    Row(
                      children: [
                        Text("Created by ", style: TextStyle(fontSize: 14)),
                        Text(
                            widget.room.createEvent?.sender.displayName ??
                                widget.room.createEvent?.senderId ??
                                "",
                            style: TextStyle(fontWeight: FontWeight.bold))
                      ],
                    )
                  ],
                ),
                trailing: Icon(Icons.navigate_next),
                leading: MatrixUserImage(
                    client: widget.room.client,
                    thumnail: true,
                    url: widget.room.avatar,
                    defaultText: widget.room.name,
                    backgroundColor: Theme.of(context).primaryColor),
                onTap: () async {
                  await context
                      .navigateTo(CalendarEventRoute(room: widget.room));
                }),
          );
        });
  }
}
