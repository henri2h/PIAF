import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'package:minestrix/utils/matrix_widget.dart';
import 'package:minestrix/utils/minestrix/minestrix_notifications.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Client? client = Matrix.of(context).client;

    return StreamBuilder(
        stream: client.onMinestrixUpdate,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          return Column(
            children: [
              IconButton(
                  icon: client.notifications.length == 0
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
