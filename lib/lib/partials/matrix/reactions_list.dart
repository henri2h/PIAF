import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:minestrix_chat/utils/extensions/matrix/event_extension.dart';
import 'matrix_user_item.dart';

class EventReactionList extends StatelessWidget {
  const EventReactionList({
    super.key,
    required this.reactions,
  });

  final Set<Event> reactions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(
        children: [
          for (Event e in reactions.where((e) => e.emoji != null))
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: MatrixUserItem(
                                name: e.senderFromMemoryOrFallback.displayName,
                                userId: e.senderId,
                                client: e.room.client,
                                avatarUrl:
                                    e.senderFromMemoryOrFallback.avatarUrl),
                          ),
                        ],
                      ),
                    ),
                    Text(timeago.format(e.originServerTs)),
                    const SizedBox(width: 8),
                    SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                            child: Text(e.emoji!,
                                style: const TextStyle(fontSize: 22)))),
                  ]),
            ),
        ],
      ),
    );
  }
}
