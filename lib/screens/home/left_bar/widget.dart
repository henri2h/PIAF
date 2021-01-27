import 'package:flutter/material.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/screens/chatsVue.dart';
import 'package:minestrix/screens/debugVue.dart';
import 'package:minestrix/screens/friendsVue.dart';
import 'package:minestrix/screens/settings.dart';
import 'package:minestrix/screens/userFeedView.dart';

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
    SClient sclient = Matrix.of(context).sclient;
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LeftBarButton(name: "Feed", icon: Icons.home, onPressed: () {}),
          LeftBarButton(
              name: "My account",
              icon: Icons.person,
              onPressed: () {
                changePage(context, UserFeedView(userId: sclient.userID),
                    "Friends vue");
              }),
          LeftBarButton(
              name: "Friends",
              icon: Icons.people,
              onPressed: () {
                changePage(context, FriendsVue(), "Friends vue");
              }),
          LeftBarButton(
            name: "Chats",
            icon: Icons.message,
            onPressed: () {
              changePage(context, ChatsVue(), "Chats view");
            },
          ),
          LeftBarButton(
              name: "Settings",
              icon: Icons.settings,
              onPressed: () {
                changePage(context, SettingsView(), "Settings");
              }),
          LeftBarButton(
            name: "Debug",
            icon: Icons.bug_report,
            onPressed: () {
              changePage(context, DebugView(), "Well... Debug time !!");
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
      padding: const EdgeInsets.all(8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            elevation: 5,
            primary: Colors.white,
            onPrimary: Colors.black,
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
