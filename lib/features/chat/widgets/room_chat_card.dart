import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../pages/room_page.dart';
import '../../../partials/typo/titles.dart';

class RoomChatCard extends StatelessWidget {
  const RoomChatCard({
    super.key,
    required this.room,
  });

  final Room room;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const H2Title("Chat"),
          Expanded(
            child: Container(
              color: Theme.of(context).cardColor,
              child: RoomPage(roomId: room.id),
            ),
          ),
        ],
      ),
    );
  }
}
