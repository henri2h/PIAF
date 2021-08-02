import 'package:flutter/material.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/screens/chat/chatsVue.dart';
import 'package:minestrix/screens/settings.dart';
import 'package:minestrix/screens/smatrix/feedView.dart';
import 'package:minestrix/screens/smatrix/friends/researchView.dart';
import 'package:minestrix/screens/smatrix/userFeedView.dart';

class NavBar extends StatelessWidget {
  const NavBar({Key key, this.changePage}) : super(key: key);

  final Function changePage;

  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Mines'Trix",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            ),
            NavBarButton(
                name: "Feed",
                icon: Icons.home,
                onPressed: () {
                  changePage(FeedView());
                }),
            NavBarButton(
                name: "My account",
                icon: Icons.person,
                onPressed: () {
                  changePage(UserFeedView(userId: sclient.userID));
                }),
            NavBarButton(
                name: "Chats",
                icon: Icons.chat,
                onPressed: () {
                  changePage(ChatsVue(), chatVue: true);
                }),
            NavBarButton(
                name: "Research",
                icon: Icons.search,
                onPressed: () {
                  changePage(ResearchView());
                }),
            NavBarButton(
                name: "Settings",
                icon: Icons.settings,
                onPressed: () {
                  changePage(SettingsView());
                }),
          ],
        ),
        StreamBuilder(
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
            })
      ]),
    );
  }
}

class NavBarButton extends StatelessWidget {
  const NavBarButton({Key key, this.name, this.icon, @required this.onPressed})
      : super(key: key);
  final String name;
  final IconData icon;
  final Function onPressed;
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(primary: Colors.black),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(icon),
            SizedBox(width: 5),
            Text(name,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
