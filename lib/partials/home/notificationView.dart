import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/friendsRequestList.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix/utils/minestrix/minestrix_notifications.dart';

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
        builder: (BuildContext context, AsyncSnapshot snapshot) => ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('Notifications'),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                if (!client.hasNotifications)
                  Text("No notifications, please come back later ;)"),
                for (var notif in client.notifications)
                  ListTile(
                      leading: Icon(Icons.notifications),
                      title: Text(notif.title),
                      subtitle: Text(notif.body)),
                FriendRequestList(),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
