import 'package:flutter/material.dart';
import 'package:minestrix/pages/debugPage.dart';
import 'package:minestrix/pages/minestrix/friends/friendsVue.dart';
import 'package:minestrix/pages/minestrix/userFeedPage.dart';
import 'package:minestrix/pages/settingsPage.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix_chat/view/matrix_chats_page.dart';

class LeftBar extends StatelessWidget {
  const LeftBar({Key key}) : super(key: key);
  void changePage(context, Widget widgetIn, String pageTitle) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => new Scaffold(
              appBar: AppBar(title: Text(pageTitle)), body: widgetIn)),
    );
  }

  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient;
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LeftBarButton(name: "Feed", icon: Icons.home, onPressed: () {}),
          LeftBarButton(
              name: "My account",
              icon: Icons.person,
              onPressed: () {
                changePage(context, UserFeedPage(userId: sclient.userID),
                    "Friends vue");
              }),
          LeftBarButton(
              name: "Friends",
              icon: Icons.people,
              onPressed: () {
                changePage(context, FriendsPage(), "Friends vue");
              }),
          LeftBarButton(
            name: "Chats",
            icon: Icons.message,
            onPressed: () {
              changePage(
                  context,
                  MatrixChatsPage(client: Matrix.of(context).sclient),
                  "Chats view");
            },
          ),
          LeftBarButton(
              name: "Settings",
              icon: Icons.settings,
              onPressed: () {
                changePage(context, SettingsPage(), "Settings");
              }),
          LeftBarButton(
            name: "Debug",
            icon: Icons.bug_report,
            onPressed: () {
              changePage(context, DebugPage(), "Well... Debug time !!");
            },
          ),
        ]);
  }
}

class LeftBarButton extends StatelessWidget {
  const LeftBarButton({Key key, this.name, this.icon, this.onPressed})
      : super(key: key);
  final String name;
  final IconData icon;
  final Function onPressed;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            elevation: 0,
            textStyle: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(icon),
              SizedBox(width: 5),
              Text(name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}
