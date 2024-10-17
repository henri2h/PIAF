import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/features/chat/widgets/settings/conv_settings_encryption_keys.dart';
import 'package:piaf/features/chat/widgets/settings/conv_settings_mutual_rooms.dart';
import 'package:piaf/partials/minestrix_chat.dart';
import 'package:piaf/utils/date_time_extension.dart';
import 'package:settings_ui/settings_ui.dart';

import '../widgets/room/room_search.dart';
import '../widgets/settings/conv_settings_permissions.dart';
import '../widgets/settings/conv_settings_room.dart';
import '../widgets/settings/conv_settings_room_media.dart';
import '../widgets/settings/conv_settings_security.dart';
import '../widgets/settings/conv_settings_users.dart';
import '../widgets/settings/items/direct_chat_widget.dart';
import '../widgets/settings/items/large_item_button.dart';
import '../widgets/settings/items/room_bridge_info.dart';
import '../../../partials/dialogs/adaptative_dialogs.dart';
import '../../../partials/matrix/matrix_image_avatar.dart';

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
      body: FutureBuilder(
          future: room.postLoad(),
          builder: (context, snapshot) {
            final topicEvent = room.stateRoomTopic;
            final totalParticpantCount =
                (room.summary.mInvitedMemberCount ?? 0) +
                    (room.summary.mJoinedMemberCount ?? 0);

            return CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: SettingsPageHeaderDelegate(room: room),
                ),
                SliverList.list(children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(room.getName(),
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8),
                      child: Text(
                          room.isDirectChat == false
                              ? "Group with ${room.summary.mJoinedMemberCount} members"
                              : room.directChatMatrixID.toString(),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.outline)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!room.encrypted)
                          LargeIconButton(
                              icon: Icons.search,
                              title: "Search",
                              onPressed: () => onPressedSearch(context, room)),
                        LargeIconButton(
                            icon: Icons.image,
                            title: "Media",
                            onPressed: () => onPressedMedia(context, room)),
                        LargeIconButton(
                            icon: Icons.settings,
                            title: "Settings",
                            onPressed: () => onPressedSettings(context, room)),
                      ],
                    ),
                  ),
                  if (room.states["m.bridge"] != null)
                    for (final event
                        in room.states["m.bridge"]?.values.toList() ?? [])
                      RoomBridgeInfo(event: event),
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
                  if (room.isDirectChat) DirectChatWidget(room: room),
                  if (room.isDirectChat) MutualRoomsWidget(room: room),
                  const SizedBox(
                    height: 16,
                  ),
                  if (room.isDirectChat == false && totalParticpantCount != 2)
                    Builder(builder: (context) {
                      final particpants = room.getParticipants().take(10);

                      bool complete =
                          particpants.length == totalParticpantCount;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
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
                        if (room.isDirectChat && room.encrypted)
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
                ])
              ],
            );
          }),
    );
  }
}

class SettingsPageHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Room room;

  SettingsPageHeaderDelegate({
    required this.room,
  });
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = shrinkOffset / maxExtent;
    return Material(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (progress != 0)
            AppBar(
              title: Row(
                children: [
                  MatrixImageAvatar(
                      url: room.avatar,
                      defaultText: room.getLocalizedDisplayname(),
                      fit: true,
                      client: room.client),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(child: Text(room.getLocalizedDisplayname())),
                ],
              ),
            ),
          SafeArea(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: 1 - progress,
              child: Column(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 260,
                      child: MatrixImageAvatar(
                          url: room.avatar,
                          client: room.client,
                          defaultText: room.getLocalizedDisplayname(),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          thumnailOnly: false,
                          unconstraigned: true,
                          shape: MatrixImageAvatarShape.none,
                          width: MinestrixAvatarSizeConstants.big,
                          height: MinestrixAvatarSizeConstants.big),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (progress != 1)
            AppBar(
              forceMaterialTransparency: true,
            ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 340;

  @override
  double get minExtent => 104;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
