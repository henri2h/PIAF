import 'package:flutter/material.dart';

class NoRoomSelected extends StatelessWidget {
  const NoRoomSelected({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat, size: 40),
              SizedBox(width: 20),
              Text("No room selected",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
            ],
          )
        ],
      ),
    );
  }
}
