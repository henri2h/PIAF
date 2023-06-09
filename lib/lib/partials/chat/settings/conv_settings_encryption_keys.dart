import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'items/conv_setting_back_button.dart';
import 'room/room_encryption_settings.dart';

class ConvSettingsEncryptionKeys extends StatefulWidget {
  final Room room;

  const ConvSettingsEncryptionKeys({required this.room, Key? key})
      : super(key: key);

  @override
  State<ConvSettingsEncryptionKeys> createState() =>
      _ConvSettingsEncryptionKeysState();
}

class _ConvSettingsEncryptionKeysState
    extends State<ConvSettingsEncryptionKeys> {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: const [
        ConvSettingsBackButton(),
        Text("Encryption keys",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      RoomUserDeviceKey(
        room: widget.room,
        userId: widget.room.directChatMatrixID!,
      ),
    ]);
  }
}
