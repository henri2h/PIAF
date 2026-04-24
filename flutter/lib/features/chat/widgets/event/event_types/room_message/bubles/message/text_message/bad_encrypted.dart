import 'package:flutter/material.dart';

class BadEncrypted extends StatelessWidget {
  const BadEncrypted({
    super.key,
    required this.colorPatch,
  });

  final Color colorPatch;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.lock_clock, color: colorPatch),
      const SizedBox(width: 10),
      Flexible(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Message encrypted", style: TextStyle(color: colorPatch)),
            Text("Waiting for encryption key, it may take a while",
                style: TextStyle(color: colorPatch, fontSize: 12))
          ],
        ),
      )
    ]);
  }
}
