import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/pages/story/create_story_page.dart';
import 'package:piaf/chat/minestrix_chat.dart';
import 'package:piaf/chat/partials/matrix/matrix_room_avatar.dart';
import 'package:piaf/chat/utils/matrix_widget.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../router.gr.dart';

@RoutePage()
class SettingsStorysPage extends StatefulWidget {
  const SettingsStorysPage({super.key});

  @override
  State<SettingsStorysPage> createState() => _SettingsStorysPageState();
}

class _SettingsStorysPageState extends State<SettingsStorysPage> {
  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    return Scaffold(
      appBar: AppBar(title: const Text("Story rooms"), actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: FilledButton.icon(
            onPressed: () async {
              await CreateStoryPage.show(context: context);
            },
            icon: const Icon(Icons.add),
            label: const Text("Add"),
          ),
        )
      ]),
      body: StreamBuilder<Object>(
          stream: client.onSync.stream,
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
                      tiles: <SettingsTile>[
                        for (final room in client.getStorieRoomsFromUser(
                            userID: client.userID!))
                          SettingsTile.navigation(
                            leading: RoomAvatar(room: room, client: client),
                            title: Text(room.getLocalizedDisplayname(
                                const MatrixDefaultLocalizations())),
                            value: Text(
                                "${room.summary.mJoinedMemberCount} followers"),
                            onPressed: (context) => context.navigateTo(
                                SettingsStorysDetailRoute(room: room)),
                          ),
                      ],
                    ),
                  ]),
            ]);
          }),
    );
  }
}
