import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/friendsRequestList.dart';
import 'package:minestrix_chat/partials/matrix/matrix_user_item.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix/utils/minestrix/minestrix_notifications.dart';

import '../components/minesTrix/MinesTrixTitle.dart';

class NotificationView extends StatelessWidget {
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
                    color: Theme.of(context).primaryColor,
                  ),
                  child: const Text('Notifications'),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(children: [
                    const H2Title("MinesTRIX notifications"),
                    if (!client.hasNotifications)
                      const Text("No notifications, please come back later ;)"),
                    for (var notif in client.notifications)
                      ListTile(
                          leading: const Icon(Icons.notifications),
                          title: Text(notif.title),
                          subtitle: Text(notif.body)),
                    FriendRequestList(),
                  ]),
                ),
                if (notificationRooms.isNotEmpty) const H2Title("Chats"),
                if (notificationRooms.isNotEmpty)
                  for (final room in notificationRooms)
                    ListTile(
                        title: MatrixUserItem(
                          client: client,
                          name: room.displayname,
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
