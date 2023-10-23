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
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: Badge(
          backgroundColor: unreadMessage ? null : Colors.red,
          label: unreadMessage
              ? const Text("0")
              : Text(room.notificationCount.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold))),
    );
  }
}
