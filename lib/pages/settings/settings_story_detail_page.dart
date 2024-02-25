import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/chat/partials/matrix/matrix_user_avatar.dart';
import 'package:piaf/chat/utils/matrix_widget.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../partials/editors/sections.dart';

@RoutePage()
class SettingsStorysDetailPage extends StatefulWidget {
  const SettingsStorysDetailPage({super.key, required this.room});
  final Room room;

  @override
  State<SettingsStorysDetailPage> createState() =>
      _SettingsStorysDetailPageState();
}

class _SettingsStorysDetailPageState extends State<SettingsStorysDetailPage> {
  void changeJoinPermissions(String? context) {}
  String get roomName => widget.room.getLocalizedDisplayname();

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
                    CustomSettingsSection(
                        child: EditorSectionInfo(
                      room: room,
                    )),
                    CustomSettingsSection(
                        child: EditorSectionJoinRules(
                      room: room,
                      description: "Who can join this story",
                    )),
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
                    CustomSettingsSection(
                      child: EditorSectionOtherSettings(room: room),
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
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              }),
                        ])
                  ]),
            ]);
          }),
    );
  }
}
