import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

class NotificationCountDot extends StatelessWidget {
  const NotificationCountDot(
      {Key? key, required this.room, this.unreadMessage = false})
      : super(key: key);

  final Room room;
  final bool unreadMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 15),
      child: CircleAvatar(
          radius: unreadMessage ? 7 : 11,
          backgroundColor: unreadMessage ? Colors.grey : Colors.red,
          child: unreadMessage
              ? null
              : Text(room.notificationCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ))),
    );
  }
}
