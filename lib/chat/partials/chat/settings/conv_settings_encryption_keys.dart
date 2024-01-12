import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'room/room_encryption_settings.dart';

class ConvSettingsEncryptionKeys extends StatefulWidget {
  final Room room;

  const ConvSettingsEncryptionKeys({required this.room, super.key});

  @override
  State<ConvSettingsEncryptionKeys> createState() =>
      _ConvSettingsEncryptionKeysState();
}

class _ConvSettingsEncryptionKeysState
    extends State<ConvSettingsEncryptionKeys> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Encryption keys"),
        forceMaterialTransparency: true,
      ),
      body: RoomUserDeviceKey(
        room: widget.room,
        userId: widget.room.directChatMatrixID!,
      ),
    );
  }
}
