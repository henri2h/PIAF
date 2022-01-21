import 'package:flutter/material.dart';
import 'package:minestrix/partials/components/friendsRequestList.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixNotifications.dart';

class NotificationView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;
    MinestrixNotifications n = sclient.notifications;

    return Drawer(
      // Add a ListView to the drawer. This ensures the user can scroll
      // through the options in the drawer if there isn't enough vertical
      // space to fit everything.
      child: StreamBuilder(
        stream: sclient.notifications.onNotifications.stream,
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
                if (!n.hasNotifications)
                  Text("No notifications, please come back later ;)"),
                for (var notif in n.notifications)
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
