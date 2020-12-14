import 'package:flutter/material.dart';

class LeftBar extends StatelessWidget {
  const LeftBar({Key key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
      LeftBarButton(name: "Feed", icon:Icons.home),
      LeftBarButton(name: "My account", icon:Icons.person),
      LeftBarButton(name: "Friends", icon:Icons.people),
      LeftBarButton(name: "Settings", icon:Icons.settings),
      LeftBarButton(name: "Debug", icon:Icons.bug_report),
      LeftBarButton(name: "Logout", icon:Icons.logout),
      ]
    );
  }
}



class LeftBarButton extends StatelessWidget {
  const LeftBarButton({Key key, this.name, this.icon}) : super(key: key);
  final String name;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}
