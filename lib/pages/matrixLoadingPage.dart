import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/partials/minestrixTitle.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';

class MatrixLoadingPage extends StatefulWidget {
  const MatrixLoadingPage({Key? key}) : super(key: key);

  @override
  _MatrixLoadingPageState createState() => _MatrixLoadingPageState();
}

class _MatrixLoadingPageState extends State<MatrixLoadingPage> {
  bool running = false;

  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;

    return Scaffold(
      body: StreamBuilder<SyncStatusUpdate>(
          stream: sclient.onSyncStatus.stream,
          builder: (context, snap) {
            if (!snap.hasData) return Center(child: MinestrixTitle());

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MinestrixTitle(),
                MaterialButton(
                    child: Text("Refresh"),
                    onPressed: () async {
                      await sclient.loadSRooms();
                    }),
                if (snap.data!.status != SyncStatus.finished)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(children: [
                          Text("Syncing",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          SizedBox(height: 20),
                          if (snap.data!.status == SyncStatus.processing)
                            LinearProgressIndicator(value: snap.data!.progress),
                          if (snap.data!.status != SyncStatus.processing)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [LinearProgressIndicator()],
                            ),

                          // check if we need to create a user room for the user
                        ]),
                      ),
                    ),
                  ),
                if (!sclient.userRoomCreated &&
                    snap.data!.status == SyncStatus.finished)
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
                              label: "Create my account",
                              icon: Icons.send)),
                if (running) LinearProgressIndicator(),
              ],
            );
          }),
    );
  }
}
