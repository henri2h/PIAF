import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';

class createMinestrixAccountPage extends StatefulWidget {
  @override
  _createMinestrixAccountPageState createState() =>
      _createMinestrixAccountPageState();
}

class _createMinestrixAccountPageState extends State<createMinestrixAccountPage> {
  bool running = false;

  @override
  Widget build(BuildContext context) {
    MinestrixClient? sclient = Matrix.of(context).sclient;

    return SafeArea(
        child: Scaffold(
            body: Padding(
      padding: const EdgeInsets.all(30),
      child: ListView(
        children: [
          H1Title("Ready to take part in the adventure ?"),
          SizedBox(height: 40),
          Padding(
              padding: const EdgeInsets.all(20.0),
              child: running
                  ? null
                  : MinesTrixButton(
                      onPressed: () async {
                        setState(() {
                          running = true;
                        });

                        await sclient!.createSMatrixUserProfile();
                      },
                      label: "Create my account",
                      icon: Icons.send)),
          if (running) LinearProgressIndicator(),
          MinesTrixButton(
              onPressed: () async {
                await sclient!.loadSRooms();
              },
              label: "Refresh",
              icon: Icons.receipt_long_sharp),
        ],
      ),
    )));
  }
}
