import 'package:flutter/material.dart';
import 'package:minestrix/components/friendsRequestList.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrix/Notifications.dart';
import 'package:minestrix/global/smatrixWidget.dart';

class NotificationView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    Notifications n = sclient.notifications;

    return Drawer(
      // Add a ListView to the drawer. This ensures the user can scroll
      // through the options in the drawer if there isn't enough vertical
      // space to fit everything.
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Text('Notifications'),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: [
              if (!n.hasNotifications)
                Text("No notifications, please come back later ;)"),
              for (var notif in n.notifications) Text(notif.body),
              FriendRequestList(),
            ]),
          ),
        ],
      ),
    );
  }
}
