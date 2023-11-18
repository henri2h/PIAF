import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/pages/room_settings_page.dart';
import 'package:minestrix_chat/partials/chat/settings/conv_settings_permissions.dart';
import 'package:minestrix_chat/partials/matrix/matrix_room_avatar.dart';

import '../../../partials/calendar_events/calendar_event_create_widget.dart';
import '../../../partials/components/layouts/custom_header.dart';
import '../../../partials/components/minestrix/minestrix_title.dart';
import '../../../partials/feed/topic_list_tile.dart';
import '../../account/accounts_details_page.dart';

@RoutePage()
class SocialSettingsPage extends StatefulWidget {
  const SocialSettingsPage({super.key, required this.room});

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
            Wrap(
              alignment: WrapAlignment.start,
              children: [
                if (room.feedType == FeedRoomType.calendar)
                  SizedBox(
                      width: 500,
                      child: Card(child: EditCalendarRoom(room: room))),
                if (room.feedType == FeedRoomType.calendar)
                  const SizedBox(
                    width: 12,
                  ),
                if (room.isProfileRoom)
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 800,
                    ),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ProfileSpaceCard(
                          profile: room,
                        ),
                      ),
                    ),
                  ),
                ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: SectionCard(
                      text: "Info",
                      children: [
                        ListTile(
                            title: const Text("Room name"),
                            subtitle: Text(room.name),
                            leading: const Icon(Icons.title),
                            trailing: room.canSendDefaultStates
                                ? const Icon(Icons.edit)
                                : null,
                            onTap: !room.canSendDefaultStates
                                ? null
                                : () async {
                                    List<String>? results =
                                        await showTextInputDialog(
                                      context: context,
                                      textFields: [
                                        DialogTextField(
                                            hintText: "Set room name",
                                            initialText: room.name)
                                      ],
                                      title: "Set room name",
                                    );
                                    if (results?.isNotEmpty == true) {
                                      await room.setName(results![0]);
                                    }
                                  }),
                        ListTile(
                            title: const Text("Room topic"),
                            subtitle: TopicBody(room: room),
                            leading: const Icon(Icons.topic),
                            trailing: room.canSendDefaultStates
                                ? const Icon(Icons.edit)
                                : null,
                            onTap: !room.canSendDefaultStates
                                ? null
                                : () async {
                                    List<String>? results =
                                        await showTextInputDialog(
                                      context: context,
                                      textFields: [
                                        DialogTextField(
                                            hintText: "Set event topic",
                                            initialText: room.topic)
                                      ],
                                      title: "Set room topic",
                                    );
                                    if (results?.isNotEmpty == true) {
                                      await room.setDescription(results![0]);
                                    }
                                  }),
                      ],
                    )),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    children: [
                      SectionCard(
                        text: "Permissions",
                        children: [
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
                      SectionCard(
                        text: "Join rules",
                        children: [
                          JoinRulesTile(
                            room: room,
                            icon: const Icon(Icons.post_add),
                            permissionName: 'Permissions',
                            permissionComment: 'Who can join the room',
                          ),
                        ],
                      ),
                      SectionCard(
                        text: "Other settings",
                        children: [
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
                    ],
                  ),
                ),
              ],
            )
          ]);
        });
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.children,
    required this.text,
  });

  final String text;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(top: 8.0, left: 8, right: 8, bottom: 8),
            child: H3Title(text),
          ),
          ...children
        ],
      ),
    );
  }
}

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
