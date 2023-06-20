import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'items/conv_setting_back_button.dart';
import 'room/room_settings.dart';

class ConvSettingsRoom extends StatelessWidget {
  final Room room;
  final VoidCallback onLeave;
  const ConvSettingsRoom({Key? key, required this.room, required this.onLeave})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: room.client.onSync.stream,
        builder: (context, snap) {
          return Column(
            children: [
              const Row(
                children: [
                  ConvSettingsBackButton(),
                  Text("Room settings",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Expanded(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: RoomSettings(room: room, onLeave: onLeave),
                    )
                  ],
                ),
              ),
            ],
          );
        });
  }
}
