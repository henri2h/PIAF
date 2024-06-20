import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/components/friends_request_list.dart';
import 'package:piaf/partials/chat/user/user_item.dart';
import 'package:piaf/partials/utils/matrix_widget.dart';
import 'package:piaf/utils/minestrix/minestrix_notifications.dart';

import '../components/minestrix/minestrix_title.dart';

class NotificationView extends StatelessWidget {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    Client client = Matrix.of(context).client;

    return Drawer(
      // Add a ListView to the drawer. This ensures the user can scroll
      // through the options in the drawer if there isn't enough vertical
      // space to fit everything.
      child: StreamBuilder(
          stream: client.onMinestrixUpdate,
          builder: (context, AsyncSnapshot snapshot) {
            final notificationRooms = client.rooms
                .where((room) => room.notificationCount > 0)
                .toList();

            return ListView(
              // Important: Remove any padding from the ListView.
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Text('Notifications'),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(children: [
                    const H2Title("Notifications"),
                    if (!client.hasNotifications)
                      const Text("No notifications, please come back later ;)"),
                    for (var notif in client.notifications)
                      ListTile(
                          leading: const Icon(Icons.notifications),
                          title: Text(notif.title),
                          subtitle: Text(notif.body)),
                    const FriendRequestList(),
                  ]),
                ),
                if (notificationRooms.isNotEmpty) const H2Title("Chats"),
                if (notificationRooms.isNotEmpty)
                  for (final room in notificationRooms)
                    ListTile(
                        title: UserItem(
                          client: client,
                          name: room.getLocalizedDisplayname(),
                          userId: room.directChatMatrixID ?? room.id,
                          avatarUrl: room.avatar,
                        ),
                        trailing: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Text(room.notificationCount.toString(),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11)))),
              ],
            );
          }),
    );
  }
}
