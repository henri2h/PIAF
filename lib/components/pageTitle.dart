import 'package:flutter/material.dart';

class PageTitle extends StatelessWidget {
  const PageTitle(this.title, {Key key}) : super(key: key);
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }
}
