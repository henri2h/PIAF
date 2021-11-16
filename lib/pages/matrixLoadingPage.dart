import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/minestrixTitle.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';

class MatrixLoadingPage extends StatelessWidget {
  const MatrixLoadingPage({Key? key}) : super(key: key);

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
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
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
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
    );
  }
}
