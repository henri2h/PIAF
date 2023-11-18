import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/buttons/custom_future_button.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../../partials/components/layouts/custom_header.dart';

@RoutePage()
class SettingsSyncPage extends StatefulWidget {
  const SettingsSyncPage({super.key});

  @override
  State<SettingsSyncPage> createState() => _SettingsSyncPageState();
}

class _SettingsSyncPageState extends State<SettingsSyncPage> {
  Room? actualRoom;
  int counter = 0;
  String global = "";

  Future<void> syncSocialRooms() async {
    await syncRooms(MatrixTypes.account);
    await syncRooms(MatrixTypes.group);
  }

  Future<void> syncRooms([String? filter]) async {
    final client = Matrix.of(context).client;
    final encryptedCount = client.rooms
        .where(
          (element) => element.encrypted,
        )
        .toList()
        .length;

    int pos = 0;

    for (final room in client.rooms) {
      if (!mounted) return;

      if (mounted) {
        setState(() {
          actualRoom = room;
          counter = 0;
          global = (pos / (1.0 * encryptedCount) * 100).toStringAsFixed(1);
        });
      }

      if ((filter == null && !room.encrypted) ||
          (filter != null && room.type != filter)) continue;

      final timeline = await room.getTimeline();
      try {
        while (timeline.canRequestHistory) {
          await timeline.requestHistory();

          if (!mounted) return;

          if (mounted) {
            setState(() {
              counter++;
            });
          }
        }
      } catch (ex, stack) {
        Logs().e("Could not fetch history for ${room.displayname}", ex, stack);
      }
      pos++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      const CustomHeader(title: "Sync"),
      ListTile(
          title: const Text("Room"),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (actualRoom != null) Text(actualRoom!.displayname),
              Text("$counter request for this rooms"),
            ],
          ),
          trailing: Text(global)),
      CustomFutureButton(
          onPressed: syncRooms,
          icon: const Icon(Icons.refresh),
          children: const [Text("Sync rooms")]),
      CustomFutureButton(
          onPressed: syncSocialRooms,
          icon: const Icon(Icons.refresh),
          children: const [Text("Sync social rooms")])
    ]);
  }
}
