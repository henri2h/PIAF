import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/partials/matrix/matrix_room_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../partials/components/layouts/custom_header.dart';
import '../../router.gr.dart';

class SettingsStorysPage extends StatefulWidget {
  const SettingsStorysPage({Key? key}) : super(key: key);

  @override
  State<SettingsStorysPage> createState() => _SettingsStorysPageState();
}

class _SettingsStorysPageState extends State<SettingsStorysPage> {
  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    return ListView(children: [
      const CustomHeader(title: "Storys"),
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
                for (final room
                    in client.getStorieRoomsFromUser(userID: client.userID!))
                  SettingsTile.navigation(
                    leading: RoomAvatar(room: room, client: client),
                    title: Text(room.getLocalizedDisplayname(
                        const MatrixDefaultLocalizations())),
                    value: Text("${room.summary.mJoinedMemberCount} followers"),
                    onPressed: (context) =>
                        context.navigateTo(const SettingsAccountRoute()),
                  ),
              ],
            ),
          ]),
    ]);
  }
}
