import 'package:flutter/material.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MinestrixClient? sclient = Matrix.of(context).sclient;

    return sclient == null
        ? Icon(Icons.error)
        : StreamBuilder(
            stream: sclient.notifications.onNotifications.stream,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              return Column(
                children: [
                  IconButton(
                      icon: sclient.notifications.notifications.length == 0
                          ? Icon(Icons.notifications_none)
                          : Icon(Icons.notifications_active),
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      }),
                ],
              );
            });
  }
}
