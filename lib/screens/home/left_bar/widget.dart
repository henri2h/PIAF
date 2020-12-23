import 'package:flutter/material.dart';
import 'package:minestrix/screens/chatsVue.dart';
import 'package:minestrix/screens/debugVue.dart';
import 'package:minestrix/screens/friendsVue.dart';
import 'package:minestrix/screens/settings.dart';
import 'package:minestrix/screens/smatrixRoomsVue.dart';

class LeftBar extends StatelessWidget {
  const LeftBar({Key key}) : super(key: key);
  void changePage(context, Widget widgetIn, String pageTitle) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => new Scaffold(
              appBar: AppBar(title: Text(pageTitle)), body: FriendsVue())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LeftBarButton(name: "Feed", icon: Icons.home, onPressed: () {}),
          LeftBarButton(
              name: "My account", icon: Icons.person, onPressed: () {}),
          LeftBarButton(
              name: "Friends",
              icon: Icons.people,
              onPressed: () {
                changePage(context, FriendsVue(), "Friends vue");
              }),
          LeftBarButton(
              name: "Settings",
              icon: Icons.settings,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsView(),
                  ),
                );
              }),
          LeftBarButton(
            name: "Debug",
            icon: Icons.bug_report,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DebugView(),
                ),
              );
            },
          ),
          LeftBarButton(
            name: "SMatrix rooms",
            icon: Icons.lock,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SMatrixRoomsVue(),
                ),
              );
            },
          ),
          LeftBarButton(
            name: "Chat",
            icon: Icons.message,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatsVue(),
                ),
              );
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
      child: RaisedButton(
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
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
