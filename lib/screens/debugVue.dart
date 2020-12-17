import 'package:flutter/material.dart';

class DebugView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:Text("Well... Debug time !!")),
      body:Text("Debug", style: TextStyle(fontSize: 20))
    );
  }
}
