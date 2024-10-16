import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../../../../../partials/matrix/matrix_user_avatar.dart';

class RoomBridgeInfo extends StatelessWidget {
  const RoomBridgeInfo({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    final protocol = event.content.tryGetMap<String, Object?>("protocol");
    final protocolDisplayName = protocol?.tryGet<String>("displayname") ?? '';
    final protocolId = protocol?.tryGet<String>("id") ?? '';
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Card(
        elevation: 4,
        child: ListTile(
            leading: MatrixUserAvatar(
              avatarUrl: Uri.tryParse(protocol?.tryGet("avatar_url") ?? ''),
              client: event.room.client,
              userId: protocolId,
              name: protocolDisplayName,
            ),
            title: const Text("Bridged with"),
            subtitle: Text(protocolDisplayName)),
      ),
    );
  }
}
