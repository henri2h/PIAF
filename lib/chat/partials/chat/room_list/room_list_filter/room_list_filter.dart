import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/chat/minestrix_chat.dart';

class RoomListFilter extends StatelessWidget {
  final Client client;
  const RoomListFilter({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const FilterSelectionItem(
                avatar: Icons.favorite, label: "Favorites"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 3),
              child: ActionChip(
                  avatar: StreamBuilder(
                      stream: client.onSync.stream,
                      builder: (context, _) {
                        final count = client.chatNotificationsCount;
                        if (count == 0) {
                          return const Icon(Icons.notifications);
                        } else {
                          return Badge.count(
                              count: count,
                              child: const Icon(Icons.notifications_active));
                        }
                      }),
                  label: const Text("Unread")),
            ),
            const FilterSelectionItem(avatar: Icons.person, label: "DM"),
            const FilterSelectionItem(avatar: Icons.group, label: "Groups"),
            const FilterSelectionItem(
                avatar: Icons.notifications_off, label: "Groups"),
          ],
        ),
      ),
    );
  }
}

class FilterSelectionItem extends StatelessWidget {
  final IconData avatar;
  final String label;
  const FilterSelectionItem(
      {super.key, required this.avatar, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 3),
      child: ActionChip(avatar: Icon(avatar), label: Text(label)),
    );
  }
}
