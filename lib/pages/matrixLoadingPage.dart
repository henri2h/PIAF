import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:minestrix/partials/components/buttons/MinesTrixButton.dart';
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
  Future<bool> waitForRoomsLoading(MinestrixClient sclient) async {
    if (sclient.roomsLoading != null) {
      await sclient.roomsLoading;
      await sclient.accountDataLoading;
      if (sclient.prevBatch?.isEmpty ?? true) {
        await sclient.onFirstSync.stream.first;
      }
    } else
      print("Can't wait for rooms loading");
    return true;
  }

  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;

    return Scaffold(
      body: StreamBuilder<String>(
          stream: sclient.onSRoomsUpdate.stream,
          builder: (context, _) {
            return StreamBuilder<SyncStatusUpdate>(
                stream: sclient.onSyncStatus.stream,
                builder: (context, snap) {
                  if (!snap.hasData) return Center(child: MinestrixTitle());

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MinestrixTitle(),
                      FutureBuilder(
                          future: waitForRoomsLoading(sclient),
                          builder: (context, snapLoading) {
                            print("Snap loading : " +
                                (snapLoading.data?.toString() ?? 'null'));

                            if (!snapLoading.hasData ||
                                sclient.userRoomCreated ||
                                !sclient.sroomsLoaded) {
                              if (snap.data!.status != SyncStatus.finished)
                                return Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(children: [
                                        Text("Syncing",
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold)),
                                        SizedBox(height: 20),
                                        if (snap.data!.status ==
                                            SyncStatus.processing)
                                          LinearProgressIndicator(
                                              value: snap.data!.progress),
                                        if (snap.data!.status !=
                                            SyncStatus.processing)
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              LinearProgressIndicator()
                                            ],
                                          ),

                                        // check if we need to create a user room for the user
                                      ]),
                                    ),
                                  ),
                                );
                              return Container();
                            }

                            return Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: running
                                    ? null
                                    : MinesTrixButton(
                                        onPressed: () async {
                                          setState(() {
                                            running = true;
                                          });

                                          await sclient
                                              .createSMatrixUserProfile();
                                        },
                                        label: "Create my account",
                                        icon: Icons.send));
                          }),
                      MaterialButton(
                          child: Text("Load all rooms"),
                          onPressed: () async {
                            await sclient.loadSRooms();
                          }),
                      if (running) LinearProgressIndicator(),
                    ],
                  );
                });
          }),
    );
  }
}
