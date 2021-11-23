import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';

class NavBarDesktop extends StatelessWidget {
  const NavBarDesktop({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("MinesTRIX",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            ),
            NavBarButton(
                name: "Feed",
                icon: Icons.home,
                onPressed: () {
                  context.pushRoute(FeedRoute());
                }),
            NavBarButton(
                name: "My account",
                icon: Icons.person,
                onPressed: () {
                  context.pushRoute(UserFeedRoute(userId: sclient.userID));
                }),
            NavBarButton(
                name: "Chats",
                icon: Icons.chat,
                onPressed: () {
                  context.pushRoute(
                      MatrixChatsRoute(client: Matrix.of(context).sclient!));
                }),
            NavBarButton(
                name: "Search",
                icon: Icons.search,
                onPressed: () {
                  context.pushRoute(ResearchRoute());
                }),
            NavBarButton(
                name: "Settings",
                icon: Icons.settings,
                onPressed: () {
                  context.pushRoute(SettingsRoute());
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
  const NavBarButton({Key? key, this.name, this.icon, required this.onPressed})
      : super(key: key);
  final String? name;
  final IconData? icon;
  final Function onPressed;
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed as void Function()?,
      style: TextButton.styleFrom(
          primary: Theme.of(context).textTheme.bodyText1!.color),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(icon),
            SizedBox(width: 5),
            Text(name!,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

class NavBarMobile extends StatefulWidget {
  NavBarMobile({Key? key}) : super(key: key);
  @override
  NavBarMobileState createState() => NavBarMobileState();
}

class NavBarMobileState extends State<NavBarMobile> {
  int _selectedIndex = 0;
  String? userId;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.pushRoute(FeedRoute());
        break;
      case 1:
        context
            .pushRoute(MatrixChatsRoute(client: Matrix.of(context).sclient!));
        break;
      case 2:
        context.pushRoute(UserFeedRoute(userId: userId));
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;
    userId = sclient.userID;

    return BottomNavigationBar(
      onTap: _onItemTapped,
      currentIndex: _selectedIndex,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Feed'),
        BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined), label: "Messages"),
        BottomNavigationBarItem(
            icon: FutureBuilder(
                future: sclient.getProfileFromUserId(sclient.userID!),
                builder: (BuildContext context, AsyncSnapshot<Profile> p) {
                  if (p.data?.avatarUrl == null) return Icon(Icons.person);
                  return MatrixUserImage(
                      client: sclient,
                      url: p.data!.avatarUrl,
                      fit: true,
                      thumnail: true);
                }),
            label: "My account"),
      ],
    );
  }
}
