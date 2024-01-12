import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

class SyncStatusCard extends StatelessWidget {
  final Client client;
  const SyncStatusCard({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatusUpdate>(
        stream: client.onSyncStatus.stream,
        builder: (context, snap) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (snap.data != null &&
                  snap.data?.status != SyncStatus.finished &&
                  snap.data?.status != SyncStatus.waitingForResponse &&
                  ![0, 1, null].contains(snap.data?.progress))
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        Text(snap.data!.status.toString()),
                        const Text("Syncing",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        if (snap.data?.status == SyncStatus.processing)
                          LinearProgressIndicator(value: snap.data!.progress),
                        if (snap.data?.status != SyncStatus.processing)
                          const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [LinearProgressIndicator()],
                          ),

                        // check if we need to create a user room for the user
                      ]),
                    ),
                  ),
                ),
            ],
          );
        });
  }
}
