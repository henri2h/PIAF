import 'package:flutter/material.dart';

class AppTitle extends StatelessWidget {
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(50),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(
          children: [
            Image.asset("assets/piaf.jpg",
                width: 72, height: 72, cacheWidth: 140),
            const SizedBox(width: 28),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("PIAF",
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
