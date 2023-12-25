import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/minestrix/minestrix_title.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/pages/room_settings_page.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../../partials/components/buttons/custom_future_button.dart';
import '../../partials/components/buttons/custom_text_future_button.dart';
import '../../partials/editors/sections.dart';
import '../../router.gr.dart';
import '../feed/feed_list_page.dart';

@RoutePage()
class SettingsFeedsPage extends StatefulWidget {
  const SettingsFeedsPage({super.key});

  @override
  SettingsFeedsPageState createState() => SettingsFeedsPageState();
}

class SettingsFeedsPageState extends State<SettingsFeedsPage> {
  @override
  Widget build(BuildContext context) {
    Client client = Matrix.of(context).client;

    return Scaffold(
      appBar: AppBar(title: const Text("Your profile space")),
      body: StreamBuilder(
          stream: client.onSync.stream.where((event) => event.hasRoomUpdate),
          builder: (context, _) {
            Room? profile = client.getProfileSpace();

            // room not in our profile space
            final roomsNotInOurSpace = client.srooms
                .where((sroom) =>
                    sroom.creatorId == client.userID &&
                    sroom.feedType == FeedRoomType.user &&
                    (profile?.spaceChildren.indexWhere(
                                (final sc) => sc.roomId == sroom.id) ??
                            -1) ==
                        -1)
                .toSet();

            return ListView(
              children: [
                profile == null
                    ? NoProfileSpaceFound(client: client)
                    : Card(
                        child: Wrap(
                          children: [
                            ProfileSpaceCard(profile: profile),
                          ],
                        ),
                      ),
                if (roomsNotInOurSpace.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: H3Title("Rooms not in our profile space"),
                  ),
                for (Room room in roomsNotInOurSpace)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Builder(builder: (context) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    RoomProfileListTile(room,
                                        onLeave: () async {
                                      if (profile != null &&
                                          profile.spaceChildren.indexWhere(
                                                  (final sc) =>
                                                      sc.roomId == room.id) !=
                                              -1) {
                                        await profile.removeSpaceChild(room.id);
                                      }
                                      setState(() {});
                                    }),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CustomTextFutureButton(
                                    icon: Icons.add,
                                    onPressed: () async {
                                      await profile?.setSpaceChild(room.id);
                                    },
                                    expanded: false,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    text: "Add to profile"),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            );
          }),
    );
  }
}

class ProfileSpaceCard extends StatefulWidget {
  const ProfileSpaceCard({
    super.key,
    required this.profile,
  });

  final Room profile;

  @override
  State<ProfileSpaceCard> createState() => _ProfileSpaceCardState();
}

class _ProfileSpaceCardState extends State<ProfileSpaceCard> {
  @override
  Widget build(BuildContext context) {
    final room = widget.profile;

    final client = room.client;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: MatrixImageAvatar(
                      url: room.avatar,
                      client: room.client,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      defaultText: room.name,
                      width: 80,
                      height: 80),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(room.name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      if (room.topic.isNotEmpty) Text(room.topic),
                      if (room.joinRules == JoinRules.public)
                        const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Row(
                            children: [
                              Text("Public profile space",
                                  style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      Text(room.canonicalAlias,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () =>
                    RoomSettingsPage.show(context: context, room: room)),
          ),
        ),
        LayoutBuilder(builder: (context, constraints) {
          final leftBar = Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 26),
                child: RoomInfo(r: room),
              ),
            ],
          );

          final rightBar = Column(
            children: [
              ListTile(
                  title: const Text("Rooms"),
                  trailing: FeedsAddMenuButton(client: client)),
              for (final s in room.spaceChildren
                  .where((element) => element.roomId != null))
                Builder(builder: (context) {
                  final room = client.getRoomById(s.roomId!);

                  if (room == null) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 80.0),
                      child: ListTile(
                          leading: const Icon(Icons.error),
                          title: Text("Unknown room ${s.roomId!}"),
                          trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await widget.profile
                                    .removeSpaceChild(s.roomId!);
                              })),
                    );
                  }

                  return RoomProfileListTile(
                    room,
                    onLeave: () async {
                      await widget.profile.removeSpaceChild(room.id);
                    },
                    onRemoveFromProfile: () async {
                      await widget.profile.removeSpaceChild(room.id);
                    },
                  );
                }),
            ],
          );

          if (constraints.maxWidth < 530) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
              child: Column(
                children: [
                  leftBar,
                  const SizedBox(
                    height: 10,
                  ),
                  rightBar
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(width: 200, child: leftBar),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(child: rightBar),
              ],
            ),
          );
        })
      ],
    );
  }
}

class NoProfileSpaceFound extends StatelessWidget {
  const NoProfileSpaceFound({
    super.key,
    required this.client,
  });

  final Client client;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Card(
        child: Wrap(
          direction: Axis.horizontal,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceAround,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                    child: Icon(Icons.person, size: 50),
                  ),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("No user space found",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4),
                          Text(
                              "A user space is used to allow store your profile information. It can be used by other users to discover your MinesTRIX profile.")
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomFutureButton(
                  onPressed: () async {
                    await client.createProfileSpace();
                  },
                  color: Theme.of(context).colorScheme.primary,
                  expanded: false,
                  icon: Icon(Icons.add,
                      color: Theme.of(context).colorScheme.onPrimary),
                  children: [
                    Text("Create user space",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary))
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}

class RoomProfileListTile extends StatelessWidget {
  const RoomProfileListTile(this.r,
      {super.key, required this.onLeave, this.onRemoveFromProfile});
  final Room r;
  final VoidCallback onLeave;
  final VoidCallback? onRemoveFromProfile;

  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: MatrixImageAvatar(
          url: r.avatar,
          client: r.client,
          defaultText: r.displayname,
        ),
        title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                r.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
              )
            ]),
        subtitle: RoomRowInfo(r: r),
        trailing: PopupMenuButton<String>(
            itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: "settings",
                      child: Row(children: [
                        Icon(
                          Icons.settings,
                        ),
                        SizedBox(width: 10),
                        Text("Settings"),
                      ])),
                  if (onRemoveFromProfile != null)
                    const PopupMenuItem(
                      value: "remove",
                      child: Row(children: [
                        Icon(Icons.remove),
                        SizedBox(width: 10),
                        Text("Remove from profile")
                      ]),
                    ),
                  const PopupMenuItem(
                      value: "leave",
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, color: Colors.red),
                          SizedBox(width: 10),
                          Text("Leave", style: TextStyle(color: Colors.red)),
                        ],
                      ))
                ],
            icon: const Icon(Icons.more_horiz),
            onSelected: (String action) async {
              switch (action) {
                case "settings":
                  await context.pushRoute(SocialSettingsRoute(room: r));
                  break;
                case "leave":
                  await r.leave();
                  onLeave();
                  break;
                case "remove":
                  onRemoveFromProfile?.call();
                  break;
                default:
              }
            }),
        onTap: () {
          context.navigateTo(UserViewRoute(mroom: r));
        });
  }
}

class RoomInfo extends StatelessWidget {
  const RoomInfo({
    super.key,
    required this.r,
  });

  final Room r;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      text: 'Info',
      children: [
        if (r.topic != "")
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(r.topic,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium),
          ),
        if (r.joinRules == JoinRules.invite)
          const Row(
            children: [
              Icon(Icons.person),
              SizedBox(width: 10),
              Text("Private"),
            ],
          ),
        if (r.joinRules == JoinRules.knock)
          const Row(
            children: [
              Icon(Icons.person),
              SizedBox(width: 10),
              Text("Knock"),
            ],
          ),
        if (r.joinRules == JoinRules.public)
          const Row(
            children: [
              Icon(Icons.public),
              SizedBox(width: 10),
              Text("Public"),
            ],
          ),
        Row(
          children: [
            const Icon(Icons.people),
            const SizedBox(width: 10),
            Text("${r.summary.mJoinedMemberCount} followers"),
          ],
        ),
        if (r.encrypted)
          const Row(
            children: [
              Icon(Icons.verified_user),
              SizedBox(width: 10),
              Text("Encrypted")
            ],
          ),
        if (!r.encrypted)
          const Row(
            children: [
              Icon(Icons.no_encryption),
              SizedBox(width: 10),
              Text("Not encrypted")
            ],
          ),
      ],
    );
  }
}

class RoomRowInfo extends StatelessWidget {
  const RoomRowInfo({
    super.key,
    required this.r,
  });

  final Room r;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (r.topic != "")
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(r.topic,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Row(
            children: [
              const Icon(Icons.people),
              const SizedBox(width: 10),
              Text("${r.summary.mJoinedMemberCount}"),
            ],
          ),
        ),
        Card(
          child: Row(
            children: [
              if (r.joinRules == JoinRules.public) const Icon(Icons.public),
              r.encrypted
                  ? const Icon(Icons.verified_user)
                  : const Icon(Icons.no_encryption),
            ],
          ),
        ),
      ],
    );
  }
}
