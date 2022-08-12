import 'package:flutter/material.dart';

class MinestrixTitle extends StatelessWidget {
  const MinestrixTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(50),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(
          children: [
            Image.asset("assets/icon_512.png",
                width: 72, height: 72, cacheWidth: 140),
            SizedBox(width: 28),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("MinesTRIX",
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                  Text("A privacy focused social media based on MATRIX",
                      style: TextStyle(fontSize: 16))
                ],
              ),
            ),
          ],
        ),
      ]),
    );
  }
}
