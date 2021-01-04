import 'package:flutter/material.dart';

class H1Title extends StatelessWidget {
  const H1Title(this.title, {Key key}) : super(key: key);
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(title,
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
    );
  }
}
class H2Title extends StatelessWidget {
  const H2Title(this.title, {Key key}) : super(key: key);
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(title,
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
    );
  }
}
