import 'package:flutter/material.dart';

class LoginTitle extends StatelessWidget {
  const LoginTitle({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(50),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Mines'Trix",
                style: TextStyle(fontSize: 50, fontWeight: FontWeight.w800)),
            Text("An alternative social media based on MATRIX",
                style: TextStyle(fontSize: 30))
          ]),
    );
  }
}
