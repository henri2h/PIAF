import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'room/room_settings.dart';

class ConvSettingsRoom extends StatelessWidget {
  final Room room;
  final VoidCallback onLeave;
  const ConvSettingsRoom({super.key, required this.room, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: room.client.onSync.stream,
        builder: (context, snap) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text("Room settings"),
              forceMaterialTransparency: true,
            ),
            body: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RoomSettings(room: room, onLeave: onLeave),
                )
              ],
            ),
          );
        });
  }
}
