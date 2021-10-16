import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';

class MinesTrixAccountCreation extends StatefulWidget {
  @override
  _MinesTrixAccountCreationState createState() =>
      _MinesTrixAccountCreationState();
}

class _MinesTrixAccountCreationState extends State<MinesTrixAccountCreation> {
  bool running = false;

  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;

    return SafeArea(
        child: Scaffold(
            body: Padding(
      padding: const EdgeInsets.all(30),
      child: ListView(
        children: [
          H1Title("Ready to take part in the adventure ?"),
          SizedBox(height: 40),
          StreamBuilder<SyncStatusUpdate>(
            stream: sclient.onSyncStatus.stream,
            builder: (context, snap) {
              return Column(
                children: [
                  Text("Sync status"),
                  Text("Status : " + snap.data.status.toString()),
                  Text("Progress : " + snap.data.progress.toString()),
                  Text(snap.data.error.toString()),
                  Text(snap.connectionState.index.toString()),
                ],
              );
            },
          ),
          StreamBuilder<bool>(
            stream: sclient.onFirstSync.stream,
            builder: (context, snap) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text("First sync"),
                    Text("first sync : " + snap.data.toString()),
                  ],
                ),
              );
            },
          ),
          Padding(
              padding: const EdgeInsets.all(20.0),
              child: running
                  ? null
                  : MinesTrixButton(
                      onPressed: () async {
                        setState(() {
                          running = true;
                        });

                        await sclient.createSMatrixUserProfile();
                      },
                      label: "Go",
                      icon: Icons.send)),
          if (running) LinearProgressIndicator(),
        ],
      ),
    )));
  }
}
