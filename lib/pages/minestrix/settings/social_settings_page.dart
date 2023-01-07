import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/layouts/custom_header.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/chat/settings/conv_settings_permissions.dart';
import 'package:minestrix_chat/partials/matrix/matrix_room_avatar.dart';
import 'package:minestrix_chat/view/room_settings_page.dart';

class SocialSettingsPage extends StatefulWidget {
  const SocialSettingsPage({Key? key, required this.room}) : super(key: key);

  final Room room;

  @override
  State<SocialSettingsPage> createState() => _SocialSettingsPageState();
}

class _SocialSettingsPageState extends State<SocialSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    return StreamBuilder<Object>(
        stream: room.onUpdate.stream,
        builder: (context, snapshot) {
          return ListView(children: [
            CustomHeader(
                title:
                    "${room.getLocalizedDisplayname(const MatrixDefaultLocalizations())} settings"),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const H2Title("Permissions"),
                          PermissionTile(
                            room: room,
                            icon: const Icon(Icons.post_add),
                            permissionName: 'Posting',
                            permissionComment: 'Who can send posts',
                            eventType: MatrixTypes.post,
                          ),
                          PermissionTile(
                            room: room,
                            icon: const Icon(Icons.comment),
                            permissionName: 'Commenting',
                            permissionComment: 'Who can comment on posts',
                            eventType: MatrixTypes.comment,
                          ),
                        ],
                      ),
                    ),
                    Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const H2Title("Join rules"),
                          JoinRulesTile(
                            room: room,
                            icon: const Icon(Icons.post_add),
                            permissionName: 'Permissions',
                            permissionComment: 'Who can join the room',
                          ),
                        ],
                      ),
                    ),
                    Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const H2Title("Other settings"),
                          ListTile(
                            title: const Text("Settings"),
                            subtitle: const Text("Default room settings"),
                            leading: const Icon(Icons.settings),
                            trailing: const Icon(Icons.edit),
                            onTap: () {
                              RoomSettingsPage.show(
                                  context: context, room: room);
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
          ]);
        });
  }
}

class JoinRulesTile extends StatelessWidget {
  const JoinRulesTile({
    Key? key,
    required this.room,
    required this.icon,
    required this.permissionName,
    this.permissionComment,
  }) : super(key: key);

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
