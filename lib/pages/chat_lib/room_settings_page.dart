library minestrix_chat;

import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/chat/partials/chat/settings/conv_settings_encryption_keys.dart';
import 'package:piaf/chat/partials/chat/settings/conv_settings_mutual_rooms.dart';
import 'package:piaf/chat/partials/matrix/matrix_user_avatar.dart';
import 'package:piaf/utils/date_time_extension.dart';
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
  void onPressedSearch(BuildContext context, Room room) async {
    await AdaptativeDialogs.show(
        context: context, builder: (context) => RoomSearch(room: room));
  }

  void onPressedMedia(BuildContext context, Room room) async =>
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ConvSettingsRoomMedia(room: room)));

  void onPressedSettings(BuildContext context, Room room) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) =>
            ConvSettingsRoom(room: room, onLeave: widget.onLeave)));
  }

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
            final isDirectChat = room.isDirectChat;
            final topicEvent = room.getState(EventTypes.RoomTopic);

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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!room.encrypted)
                        GroupIcon(
                            icon: Icons.search,
                            title: "Search",
                            onPressed: () => onPressedSearch(context, room)),
                      GroupIcon(
                          icon: Icons.image,
                          title: "Media",
                          onPressed: () => onPressedMedia(context, room)),
                      GroupIcon(
                          icon: Icons.settings,
                          title: "Settings",
                          onPressed: () => onPressedSettings(context, room)),
                    ],
                  ),
                ),
                if (isDirectChat == false)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            "Group with ${room.summary.mJoinedMemberCount} members",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline)),
                      ],
                    ),
                  ),
                if (![null, ""].contains(topicEvent?.content["topic"]))
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(topicEvent!.content["topic"] as String,
                            style: Theme.of(context).textTheme.bodyLarge),
                        if (topicEvent.senderId.isNotEmpty)
                          FutureBuilder<Profile>(
                              future: room.client
                                  .getProfileFromUserId(topicEvent.senderId),
                              builder: (context, snapshot) {
                                String name = topicEvent.senderId;
                                if (snapshot.data?.displayName?.isNotEmpty ==
                                    true) {
                                  name = "${snapshot.data?.displayName}";
                                }

                                if (topicEvent is Event) {
                                  return Text(
                                      "Set by $name on ${topicEvent.originServerTs.timeSinceAWeekOrDuration}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline));
                                }

                                return Text("Set by $name");
                              })
                      ],
                    ),
                  ),
                if (isDirectChat) DirectChatWidget(room: room),
                if (isDirectChat) MutualRoomsWidget(room: room),
                const SizedBox(
                  height: 16,
                ),
                if (isDirectChat == false &&
                    ((room.summary.mInvitedMemberCount ?? 0) +
                            (room.summary.mJoinedMemberCount ?? 0)) !=
                        2)
                  Builder(builder: (context) {
                    final particpants = room.getParticipants().take(10);
                    final totalParticpantCount =
                        (room.summary.mInvitedMemberCount ?? 0) +
                            (room.summary.mJoinedMemberCount ?? 0);
                    bool complete = particpants.length == totalParticpantCount;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            "$totalParticpantCount members",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        for (final user in particpants)
                          UsersListItem(u: user, room: room),
                        if (!complete)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: TextButton(
                                onPressed: () async {
                                  await Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ConvSettingsUsers(room: room)));
                                },
                                child: Text(
                                    "See all particpants, ${totalParticpantCount - particpants.length} more")),
                          ),
                      ],
                    );
                  }),
                SettingsList(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    lightTheme: const SettingsThemeData(
                        settingsListBackground: Colors.transparent),
                    darkTheme: const SettingsThemeData(
                        settingsListBackground: Colors.transparent),
                    sections: [
                      if (isDirectChat && room.encrypted)
                        SettingsSection(title: const Text("User"), tiles: [
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
                          title: const Text('Security'),
                          tiles: <SettingsTile>[
                            SettingsTile.navigation(
                              leading: const Icon(Icons.check_circle),
                              title: const Text('Roles & permissions'),
                              onPressed: (context) async => await Navigator.of(
                                      context)
                                  .push(MaterialPageRoute(
                                      builder: (context) =>
                                          ConvSettingsPermissions(room: room))),
                            ),
                            SettingsTile.navigation(
                              leading: const Icon(Icons.lock),
                              title: const Text('Room security'),
                              onPressed: (context) async => await Navigator.of(
                                      context)
                                  .push(MaterialPageRoute(
                                      builder: (context) =>
                                          ConvSettingsSecurity(room: room))),
                            ),
                          ]),
                      SettingsSection(
                        tiles: <SettingsTile>[
                          SettingsTile(
                              leading: const Icon(
                                Icons.logout,
                                color: Colors.red,
                              ),
                              title: const Text('Leave',
                                  style: TextStyle(color: Colors.red)),
                              onPressed: (context) async {
                                await widget.room.leave();
                                widget.onLeave();
                              }),
                        ],
                      ),
                    ]),
              ],
            );
          }),
    );
  }
}

class GroupIcon extends StatelessWidget {
  final IconData icon;
  final String title;
  final void Function() onPressed;
  const GroupIcon(
      {super.key,
      required this.icon,
      required this.title,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: FilledButton.tonal(
            onPressed: onPressed,
            style: const ButtonStyle(
                padding: MaterialStatePropertyAll<EdgeInsetsGeometry?>(
                    EdgeInsets.all(8)),
                shape: MaterialStatePropertyAll<OutlinedBorder?>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16))))),
            child: SizedBox(width: 48, height: 48, child: Icon(icon, size: 28)),
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge,
        )
      ],
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
