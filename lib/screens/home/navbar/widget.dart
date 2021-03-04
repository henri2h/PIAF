import 'package:flutter/material.dart';
import 'package:minestrix/global/helpers/NavigationHelper.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';

class NavBar extends StatelessWidget {
  const NavBar({Key key}) : super(key: key);

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
            NavBarButton(name: "Feed", icon: Icons.home, onPressed: () {}),
            NavBarButton(
                name: "My Acount",
                icon: Icons.person,
                onPressed: () {
                  NavigationHelper.navigateToUserFeed(
                      context, sclient.userRoom.user);
                }),
            NavBarButton(name: "Friends", icon: Icons.people, onPressed: () {}),
          ],
        ),
        StreamBuilder(
            stream: sclient.notifications.onNotifications.stream,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              return Column(
                children: [
                  if (snapshot.hasData) Text(snapshot.data),
                  IconButton(
                      icon: Icon(Icons.notifications),
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
