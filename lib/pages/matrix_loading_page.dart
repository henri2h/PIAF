import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/app_title.dart';
import 'package:piaf/utils/minestrix/minestrix_client_extension.dart';
import 'package:piaf/utils/minestrix/minestrix_notifications.dart';
import 'package:piaf/utils/matrix_widget.dart';

import '../features/feed/widgets/minestrix_profile_not_created.dart';

@RoutePage()
class MatrixLoadingPage extends StatefulWidget {
  const MatrixLoadingPage({super.key});

  @override
  MatrixLoadingPageState createState() => MatrixLoadingPageState();
}

class MatrixLoadingPageState extends State<MatrixLoadingPage> {
  bool running = false;
  Future<bool> waitForRoomsLoading(Client sclient) async {
    if (sclient.roomsLoading != null) {
      await sclient.roomsLoading;
      await sclient.accountDataLoading;
      if (sclient.prevBatch?.isEmpty ?? true) {
        await sclient.onSync.stream.first;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    Client sclient = Matrix.of(context).client;

    return Scaffold(
      body: StreamBuilder(
          stream: sclient.onMinestrixUpdate,
          builder: (context, _) {
            return StreamBuilder<SyncStatusUpdate>(
                stream: sclient.onSyncStatus.stream,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: AppTitle());
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppTitle(),
                      FutureBuilder(
                          future: waitForRoomsLoading(sclient),
                          builder: (context, snapLoading) {
                            if (!snapLoading.hasData ||
                                sclient.userRoomCreated) {
                              if (snap.data!.status != SyncStatus.finished) {
                                return Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(children: [
                                        const Text("Syncing",
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 20),
                                        if (snap.data!.status ==
                                            SyncStatus.processing)
                                          LinearProgressIndicator(
                                              value: snap.data!.progress),
                                        if (snap.data!.status !=
                                            SyncStatus.processing)
                                          const LinearProgressIndicator()

                                        // check if we need to create a user room for the user
                                      ]),
                                    ),
                                  ),
                                );
                              }
                              return Container();
                            }
                            return const MinestrixProfileNotCreated();
                          }),
                      if (running) const LinearProgressIndicator(),
                    ],
                  );
                });
          }),
    );
  }
}
