import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/buttons/customFutureButton.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../../partials/components/layouts/customHeader.dart';

class SettingsSyncPage extends StatefulWidget {
  const SettingsSyncPage({Key? key}) : super(key: key);

  @override
  State<SettingsSyncPage> createState() => _SettingsSyncPageState();
}

class _SettingsSyncPageState extends State<SettingsSyncPage> {
  Room? actualRoom;
  int counter = 0;
  String global = "";

  Future<void> syncRooms() async {
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

      if (mounted)
        setState(() {
          actualRoom = room;
          counter = 0;
          global = (pos / (1.0 * encryptedCount) * 100).toStringAsFixed(1);
        });

      if (!room.encrypted) continue;

      final timeline = await room.getTimeline();
      while (timeline.canRequestHistory) {
        await timeline.requestHistory();

        if (!mounted) return;

        if (mounted)
          setState(() {
            counter++;
          });
      }
      pos++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      CustomHeader(title: "Theme"),
      ListTile(
          title: Text("Room"),
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
          children: [Text("Sync rooms")],
          icon: Icon(Icons.refresh))
    ]);
  }
}
