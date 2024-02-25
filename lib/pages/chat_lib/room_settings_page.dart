library minestrix_chat;

import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/chat/partials/chat/settings/conv_settings_encryption_keys.dart';
import 'package:piaf/chat/partials/chat/settings/conv_settings_mutual_rooms.dart';
import 'package:piaf/chat/partials/matrix/matrix_user_avatar.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../chat/partials/chat/room/room_search.dart';
import '../../chat/partials/chat/settings/conv_settings_permissions.dart';
import '../../chat/partials/chat/settings/conv_settings_room.dart';
import '../../chat/partials/chat/settings/conv_settings_room_media.dart';
import '../../chat/partials/chat/settings/conv_settings_security.dart';
import '../../chat/partials/chat/settings/conv_settings_users.dart';
import '../../chat/partials/chat/user/user_info_dialog.dart';
import '../../chat/partials/dialogs/adaptative_dialogs.dart';
import '../../chat/partials/matrix/matrix_image_avatar.dart';

@RoutePage()
class RoomSettingsPage extends StatefulWidget {
  final VoidCallback onLeave;
  const RoomSettingsPage(
      {super.key, required this.room, required this.onLeave});

  final Room room;

  static Future<void> show(
      {required BuildContext context, required Room room}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RoomSettingsPage(
            room: room,
            onLeave: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            }),
      ),
    );
  }

  @override
  RoomSettingsPageState createState() => RoomSettingsPageState();
}

class RoomSettingsPageState extends State<RoomSettingsPage> {
  @override
  Widget build(BuildContext context) {
    Room room = widget.room;
    final backgroundColor =
        Platform.isAndroid || Platform.isIOS ? null : Colors.transparent;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(room.getLocalizedDisplayname()),
        backgroundColor: backgroundColor,
        forceMaterialTransparency: true,
      ),
      body: FutureBuilder(
          future: room.postLoad(),
          builder: (context, snapshot) {
            return ListView(
              children: [
                SizedBox(
                  height: 260,
                  child: MatrixImageAvatar(
                      url: room.avatar,
                      client: widget.room.client,
                      defaultText: room.getLocalizedDisplayname(),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      thumnailOnly: false,
                      unconstraigned: true,
                      shape: MatrixImageAvatarShape.none,
                      width: MinestrixAvatarSizeConstants.big,
                      height: MinestrixAvatarSizeConstants.big),
                ),
                if (room.states["m.bridge"] != null)
                  for (final event
                      in room.states["m.bridge"]?.values.toList() ?? [])
                    RoomBridgeInfo(event: event),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (room.topic.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(room.topic,
                                  style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      if (room.isDirectChat) DirectChatWidget(room: room),
                      SettingsList(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          lightTheme: const SettingsThemeData(
                              settingsListBackground: Colors.transparent),
                          darkTheme: const SettingsThemeData(
                              settingsListBackground: Colors.transparent),
                          sections: [
                            if (room.isDirectChat)
                              SettingsSection(
                                  title: const Text("User"),
                                  tiles: [
                                    SettingsTile.navigation(
                                      leading: const Icon(Icons.room),
                                      title: const Text('Mutual rooms'),
                                      onPressed: (context) async =>
                                          await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      ConvSettingsMutualRooms(
                                                        room: room,
                                                      ))),
                                    ),
                                    if (room.encrypted)
                                      SettingsTile.navigation(
                                        leading: const Icon(Icons.lock_sharp),
                                        title: const Text('Encryption keys'),
                                        onPressed: (context) async =>
                                            await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        ConvSettingsEncryptionKeys(
                                                            room: room))),
                                      ),
                                  ]),
                            SettingsSection(
                                title: const Text('Room'),
                                tiles: <SettingsTile>[
                                  if (!room.encrypted)
                                    SettingsTile.navigation(
                                      leading: const Icon(Icons.search),
                                      title: const Text('Search'),
                                      onPressed: (context) async {
                                        await AdaptativeDialogs.show(
                                            context: context,
                                            builder: (context) =>
                                                RoomSearch(room: room));
                                      },
                                    ),
                                  SettingsTile.navigation(
                                    leading: const Icon(Icons.people),
                                    title: const Text('Users'),
                                    value: Text(
                                        "${room.summary.mJoinedMemberCount ?? 0} members"),
                                    onPressed: (context) async =>
                                        await Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    ConvSettingsUsers(
                                                        room: room))),
                                  ),
                                  SettingsTile.navigation(
                                      leading: const Icon(Icons.settings),
                                      title: const Text('Room settings'),
                                      onPressed: (context) async =>
                                          await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      ConvSettingsRoom(
                                                          room: room,
                                                          onLeave: widget
                                                              .onLeave)))),
                                  SettingsTile.navigation(
                                    leading: const Icon(Icons.image),
                                    title: const Text('Room media'),
                                    onPressed: (context) async =>
                                        await Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    ConvSettingsRoomMedia(
                                                        room: room))),
                                  ),
                                ]),
                            SettingsSection(
                                title: const Text('Security'),
                                tiles: <SettingsTile>[
                                  SettingsTile.navigation(
                                    leading: const Icon(Icons.check_circle),
                                    title: const Text('Roles & permissions'),
                                    onPressed: (context) async =>
                                        await Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    ConvSettingsPermissions(
                                                        room: room))),
                                  ),
                                  SettingsTile.navigation(
                                    leading: const Icon(Icons.lock),
                                    title: const Text('Room security'),
                                    onPressed: (context) async =>
                                        await Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    ConvSettingsSecurity(
                                                        room: room))),
                                  ),
                                ]),
                            SettingsSection(
                              title: const Text('Danger'),
                              tiles: <SettingsTile>[
                                SettingsTile(
                                    leading: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    title: const Text('Leave'),
                                    onPressed: (context) async {
                                      await widget.room.leave();
                                      widget.onLeave();
                                    }),
                              ],
                            ),
                          ]),
                    ],
                  ),
                ),
              ],
            );
          }),
    );
  }
}

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

class DirectChatWidget extends StatelessWidget {
  const DirectChatWidget({
    super.key,
    required this.room,
  });

  final Room room;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PresenceIndicator(room: room, userID: room.directChatMatrixID!),
      ],
    );
  }
}
