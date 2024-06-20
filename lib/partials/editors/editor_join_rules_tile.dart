import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/matrix/matrix_room_avatar.dart';

class JoinRulesTile extends StatelessWidget {
  const JoinRulesTile({
    super.key,
    required this.room,
    required this.icon,
    required this.permissionName,
    this.permissionComment,
  });

  final Room room;
  final Icon icon;
  final String permissionName;
  final String? permissionComment;

  Future<void> setRestricted(value) async {
    if (value == null) return;
    await room.client.setRoomStateWithKey(
      room.id,
      EventTypes.RoomJoinRules,
      '',
      {
        'join_rule': 'restricted',
        'allow': [
          // TODO: Set here the spaces that can allow joining this room
        ]
      },
    );
    return;
  }

  void setJoinRules(JoinRules? rules) {
    if (rules == null) return;
    room.setJoinRules(rules);
  }

  @override
  Widget build(BuildContext context) {
    final joinRuleContent = room.getState(EventTypes.RoomJoinRules)?.content;
    final joinRule = joinRuleContent?.tryGet('join_rule');

    return ExpansionTile(
      title: Text(permissionName),
      leading: icon,
      subtitle: Text(permissionComment ?? ''),
      trailing: const Icon(Icons.edit),
      children: [
        RadioListTile(
            value: JoinRules.public,
            groupValue: room.joinRules,
            title: const Text("Public"),
            subtitle: const Text("Anyone can find and join."),
            secondary: const Icon(Icons.public),
            onChanged: setJoinRules),
        RadioListTile(
            value: JoinRules.invite,
            groupValue: room.joinRules,
            title: const Text("Private"),
            subtitle: const Text("Only invited can join."),
            secondary: const Icon(Icons.private_connectivity),
            onChanged: setJoinRules),
        RadioListTile(
            value: JoinRules.knock,
            groupValue: room.joinRules,
            title: const Text("Knock"),
            subtitle: const Text("Anyone can ask to join the room."),
            secondary: const Icon(Icons.door_back_door),
            onChanged: setJoinRules),
        RadioListTile(
            value: "restricted",
            groupValue: joinRule,
            title: const Text("Space members"),
            subtitle: const Text("Anyone in a space can find and join."),
            secondary: const Icon(Icons.folder),
            onChanged: setRestricted),
        if (joinRule == "restricted")
          for (Map<String, dynamic> item
              in joinRuleContent?.tryGetList<Map<String, dynamic>>("allow") ??
                  [])
            Builder(builder: (context) {
              final roomId = item.tryGet<String>("room_id");
              final type = item.tryGet<String>("type");

              final child =
                  roomId != null ? room.client.getRoomById(roomId) : null;
              return ListTile(
                  leading: child != null
                      ? RoomAvatar(
                          room: child,
                          client: room.client,
                        )
                      : null,
                  title: Text(child?.getLocalizedDisplayname(
                          const MatrixDefaultLocalizations()) ??
                      ''),
                  subtitle: Text(type ?? ''));
            })
      ],
    );
  }
}
