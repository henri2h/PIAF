import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';

class MinesTrixAccountCreation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            body: ListView(
      children: [
        H1Title("Account creation"),
        Text("hello"),
        FlatButton(onPressed: (){}, child:Text("create account"))
      ],
    )));
  }
}
