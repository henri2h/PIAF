import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

class NotificationCountDot extends StatelessWidget {
  const NotificationCountDot({super.key, required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: Badge(
          backgroundColor: Colors.red,
          label: Text(room.notificationCount.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold))),
    );
  }
}
