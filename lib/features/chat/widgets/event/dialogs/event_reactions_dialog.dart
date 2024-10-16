import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:piaf/utils/extensions/matrix/event_extension.dart';
import '../../user/user_item.dart';

class EventReactionsDialog extends StatefulWidget {
  const EventReactionsDialog({
    super.key,
    required this.reactions,
  });

  final Set<Event> reactions;

  @override
  EventReactionsDialogState createState() => EventReactionsDialogState();
}

class EventReactionsDialogState extends State<EventReactionsDialog> {
  String? filter;

  @override
  Widget build(BuildContext context) {
    final groupedReactions =
        widget.reactions.groupSetsBy((element) => element.emoji);

    return DefaultTabController(
      length: groupedReactions.length + 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: "All  ${widget.reactions.length}"),
                for (final group in groupedReactions.entries)
                  Tab(
                    text: "${group.key}  ${group.value.length}",
                  ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ReactionList(reactions: widget.reactions),
                  for (final values in groupedReactions.values)
                    ReactionList(reactions: values),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReactionList extends StatelessWidget {
  const ReactionList({
    super.key,
    required this.reactions,
  });

  final Set<Event> reactions;

  @override
  Widget build(BuildContext context) {
    return ListView(
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
                          child: UserItem(
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
    );
  }
}
