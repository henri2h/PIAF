import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/matrix/matrix_user_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../partials/feed/topic_list_tile.dart';

@RoutePage()
class SettingsStorysDetailPage extends StatefulWidget {
  const SettingsStorysDetailPage({Key? key, required this.room})
      : super(key: key);
  final Room room;

  @override
  State<SettingsStorysDetailPage> createState() =>
      _SettingsStorysDetailPageState();
}

class _SettingsStorysDetailPageState extends State<SettingsStorysDetailPage> {
  void changeJoinPermissions(String? context) {}
  String get roomName =>
      widget.room.getLocalizedDisplayname(const MatrixDefaultLocalizations());

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    final room = widget.room;
    return Scaffold(
      appBar: AppBar(
        title: Text("Story $roomName"),
      ),
      body: FutureBuilder(
          future: room.postLoad(),
          builder: (context, snapshot) {
            return ListView(children: [
              SettingsList(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  lightTheme: const SettingsThemeData(
                      settingsListBackground: Colors.transparent),
                  darkTheme: const SettingsThemeData(
                      settingsListBackground: Colors.transparent),
                  sections: [
                    SettingsSection(
                      title: const Text("Info"),
                      tiles: <SettingsTile>[
                        SettingsTile(
                            title: const Text("Story name"),
                            value: Text(room.name),
                            leading: const Icon(Icons.title),
                            trailing: room.canSendDefaultStates
                                ? const Icon(Icons.edit)
                                : null,
                            onPressed: !room.canSendDefaultStates
                                ? null
                                : (context) async {
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
                        SettingsTile(
                            title: const Text("Story topic"),
                            value: TopicBody(room: room),
                            leading: const Icon(Icons.topic),
                            trailing: room.canSendDefaultStates
                                ? const Icon(Icons.edit)
                                : null,
                            onPressed: !room.canSendDefaultStates
                                ? null
                                : (context) async {
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
                    ),
                    SettingsSection(
                        title: const Text("Who can join this story"),
                        tiles: [
                          SettingsTileRadio.radio(
                              groupValue: room.joinRulesString,
                              value: JoinRules.invite.name,
                              onPressed: changeJoinPermissions,
                              title: const Text("Invite")),
                          SettingsTileRadio.radio(
                              groupValue: room.joinRulesString,
                              value: JoinRules.public.name,
                              onPressed: changeJoinPermissions,
                              title: const Text("Public")),
                          SettingsTileRadio.radio(
                              groupValue: room.joinRulesString,
                              value: JoinRules.knock.name,
                              onPressed: changeJoinPermissions,
                              title: const Text("Knock")),
                          SettingsTileRadio.radio(
                              groupValue: room.joinRulesString,
                              value: JoinRules.private.name,
                              onPressed: changeJoinPermissions,
                              title: const Text("Private")),
                        ]),
                    SettingsSection(
                      title: Row(
                        children: [
                          const Expanded(child: Text("Followers")),
                          ElevatedButton(
                              onPressed: () {},
                              child: const Row(
                                children: [
                                  Icon(Icons.add, size: 18),
                                  SizedBox(width: 8),
                                  Text("Add"),
                                ],
                              ))
                        ],
                      ),
                      tiles: <SettingsTile>[
                        for (final participant in room.getParticipants())
                          SettingsTile(
                              leading: MatrixUserAvatar(
                                avatarUrl: participant.avatarUrl,
                                client: client,
                                name: participant.calcDisplayname(),
                                userId: participant.id,
                              ),
                              title: Text(participant.calcDisplayname()),
                              value: Text(participant.id),
                              onPressed: (context) {}),
                      ],
                    ),
                    SettingsSection(
                        title: const Text(
                          "Danger",
                          style: TextStyle(color: Colors.red),
                        ),
                        tiles: <SettingsTile>[
                          SettingsTile(
                              title: const Text("Quit story room"),
                              description: const Text(
                                  "Warning, you won't be able to join it again!"),
                              leading: const Icon(Icons.exit_to_app,
                                  color: Colors.red),
                              onPressed: (context) async {
                                final res = await showOkCancelAlertDialog(
                                    context: context,
                                    title: "Leave $roomName",
                                    message:
                                        "Are you sure you want to leave $roomName? This operation cannot be undone.",
                                    okLabel: "Yes");

                                if (res != OkCancelResult.ok) {
                                  return;
                                }
                                await room.leave();
                                if (mounted) Navigator.of(context).pop();
                              }),
                        ])
                  ]),
            ]);
          }),
    );
  }
}

extension SettingsTileRadio on SettingsTile {
  static SettingsTile radio<T>(
      {void Function(T value)? onPressed,
      required Widget title,
      required T value,
      required T groupValue}) {
    return SettingsTile(
      leading: Radio<T>(
        onChanged: (val) {
          if (val != null) {
            onPressed?.call(val);
          }
        },
        value: value,
        groupValue: groupValue,
      ),
      title: title,
      onPressed: (_) => onPressed?.call(value),
    );
  }
}

extension JoinRulesExtension on Room {
  String? get joinRulesString =>
      getState(EventTypes.RoomJoinRules)?.content.tryGet<String>('join_rule');
}
