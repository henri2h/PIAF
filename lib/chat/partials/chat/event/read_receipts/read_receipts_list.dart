import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../user/user_item.dart';

class ReadReceiptsList extends StatelessWidget {
  const ReadReceiptsList({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: event.receipts.length,
        itemBuilder: (context, index) {
          final r = event.receipts[index];
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: UserItem(
                      name: r.user.displayName,
                      userId: r.user.id,
                      client: event.room.client,
                      avatarUrl: r.user.avatarUrl),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(timeago.format(r.time)),
              )
            ],
          );
        });
  }
}
