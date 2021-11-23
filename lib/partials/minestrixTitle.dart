import 'package:flutter/material.dart';

class MinestrixTitle extends StatelessWidget {
  const MinestrixTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(50),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("MinesTRIX",
                style: TextStyle(fontSize: 50, fontWeight: FontWeight.w800)),
            Text("An privacy focused social media based on MATRIX",
                style: TextStyle(fontSize: 30))
          ]),
    );
  }
}
