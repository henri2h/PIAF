import 'package:flutter/material.dart';
import 'package:minestrix/pages/minestrix/feedPage.dart';
import 'package:minestrix/pages/minestrix/friends/researchPage.dart';
import 'package:minestrix/pages/minestrix/userFeedPage.dart';
import 'package:minestrix/pages/settingsPage.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix_chat/view/matrix_chats_page.dart';

class NavBar extends StatelessWidget {
  const NavBar({Key key, this.changePage}) : super(key: key);

  final Function changePage;

  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient;
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
                  changePage(FeedPage());
                }),
            NavBarButton(
                name: "My account",
                icon: Icons.person,
                onPressed: () {
                  changePage(UserFeedPage(userId: sclient.userID));
                }),
            NavBarButton(
                name: "Chats",
                icon: Icons.chat,
                onPressed: () {
                  changePage(
                      MatrixChatsPage(client: Matrix.of(context).sclient),
                      chatVue: true);
                }),
            NavBarButton(
                name: "Research",
                icon: Icons.search,
                onPressed: () {
                  changePage(ResearchPage());
                }),
            NavBarButton(
                name: "Settings",
                icon: Icons.settings,
                onPressed: () {
                  changePage(SettingsPage());
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
      style: TextButton.styleFrom(
          primary: Theme.of(context).textTheme.bodyText1.color),
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
