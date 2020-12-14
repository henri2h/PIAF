import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  const NavBar({Key key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Mines'Trix",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
        ),
        NavBarButton(name: "Feed", icon: Icons.home),
        NavBarButton(name: "My Acount", icon: Icons.person),
        NavBarButton(name: "Friends", icon: Icons.people)
      ]),
    );
  }
}

class NavBarButton extends StatelessWidget {
  const NavBarButton({Key key, this.name, this.icon}) : super(key: key);
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
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }
}
