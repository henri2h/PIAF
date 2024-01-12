import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix/chat/minestrix_chat.dart';

import 'package:minestrix/router.gr.dart';

class CalendarEventListTile extends StatefulWidget {
  final Room room;
  const CalendarEventListTile({super.key, required this.room});

  @override
  State<CalendarEventListTile> createState() => _CalendarEventListTileState();
}

class _CalendarEventListTileState extends State<CalendarEventListTile> {
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
                    Wrap(
                      children: [
                        const Text("Created by ",
                            style: TextStyle(fontSize: 14)),
                        Text(
                            widget.room.createEvent?.senderFromMemoryOrFallback
                                    .displayName ??
                                widget.room.createEvent?.senderId ??
                                "",
                            style: const TextStyle(fontWeight: FontWeight.bold))
                      ],
                    )
                  ],
                ),
                trailing: const Icon(Icons.navigate_next),
                leading: MatrixImageAvatar(
                    client: widget.room.client,
                    url: widget.room.avatar,
                    defaultText: widget.room.name,
                    backgroundColor: Theme.of(context).colorScheme.primary),
                onTap: () async {
                  await context
                      .navigateTo(CalendarEventRoute(room: widget.room));
                }),
          );
        });
  }
}
