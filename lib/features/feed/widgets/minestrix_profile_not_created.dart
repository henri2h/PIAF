import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'package:piaf/partials/buttons/custom_future_button.dart';
import 'package:piaf/utils/matrix_widget.dart';
import 'package:piaf/utils/minestrix/minestrix_client_extension.dart';

class MinestrixProfileNotCreated extends StatelessWidget {
  const MinestrixProfileNotCreated({
    super.key,
  });

  Future<bool> getRoomStatus(Client client) async {
    await client.roomsLoading;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final sclient = Matrix.of(context).client;

    return FutureBuilder(
        future: getRoomStatus(sclient),
        builder: (context, snap) {
          if (!snap.hasData) return Container();
          return CustomFutureButton(
              icon: Icon(Icons.skateboarding_outlined,
                  color: Theme.of(context).colorScheme.onPrimary),
              color: Theme.of(context).colorScheme.primary,
              onPressed: sclient.createPrivateMinestrixProfile,
              children: [
                Text("Create your private MinesTRIX profile",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onPrimary)),
                Text("Start posting",
                    style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onPrimary)),
              ]);
        });
  }
}
