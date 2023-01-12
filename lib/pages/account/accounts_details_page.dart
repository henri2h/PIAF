import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/buttons/custom_text_future_button.dart';
import 'package:minestrix/partials/components/layouts/custom_header.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/utils/profile_space.dart';
import 'package:minestrix_chat/view/room_settings_page.dart';

import '../../partials/components/buttons/custom_future_button.dart';
import '../../utils/settings.dart';

class AccountsDetailsPage extends StatefulWidget {
  const AccountsDetailsPage({Key? key}) : super(key: key);

  @override
  AccountsDetailsPageState createState() => AccountsDetailsPageState();
}

class AccountsDetailsPageState extends State<AccountsDetailsPage> {
  @override
  Widget build(BuildContext context) {
    Client client = Matrix.of(context).client;

    return StreamBuilder(
        stream: client.onSync.stream.where((event) => event.hasRoomUpdate),
        builder: (context, _) {
          ProfileSpace? profile = ProfileSpace.getProfileSpace(client);

          final rooms = client.srooms
              .where((sroom) =>
                  sroom.creatorId == client.userID &&
                  sroom.feedType == FeedRoomType.user &&
                  (profile?.r.spaceChildren.indexWhere(
                              (final sc) => sc.roomId == sroom.id) ??
                          -1) ==
                      -1)
              .toSet();

          return ListView(
            children: [
              const CustomHeader(title: "Your profiles space"),
              profile == null
                  ? NoProfileSpaceFound(client: client)
                  : Card(
                      child: Wrap(
                        children: [
                          ProfileSpaceCard(profile: profile),
                        ],
                      ),
                    ),
              for (Room room in rooms)
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
                                  RoomProfileListTile(room, onLeave: () async {
                                    if (profile != null &&
                                        profile.r.spaceChildren.indexWhere(
                                                (final sc) =>
                                                    sc.roomId == room.id) !=
                                            -1) {
                                      await profile.r.removeSpaceChild(room.id);
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
                                    await profile?.r.setSpaceChild(room.id);
                                  },
                                  expanded: false,
                                  color: Theme.of(context).primaryColor,
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
        });
  }
}

class ProfileSpaceCard extends StatefulWidget {
  const ProfileSpaceCard({
    Key? key,
    required this.profile,
  }) : super(key: key);

  final ProfileSpace profile;

  @override
  State<ProfileSpaceCard> createState() => _ProfileSpaceCardState();
}

class _ProfileSpaceCardState extends State<ProfileSpaceCard> {
  @override
  Widget build(BuildContext context) {
    final room = widget.profile.r;

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
                      backgroundColor: Theme.of(context).primaryColor,
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
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Row(
                            children: const [
                              Text("Public profile space",
                                  style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
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
              Card(
                  color: Theme.of(context).primaryColor,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(room.canonicalAlias,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                        )),
                  )),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 26),
                child: RoomInfo(r: room),
              ),
              Column(
                children: [
                  CustomTextFutureButton(
                      onPressed: () async {
                        await widget.profile.createStoriesRoom();
                        setState(() {});
                      },
                      text: "Create stories room",
                      color: Theme.of(context).primaryColor,
                      icon: Icons.add_a_photo),
                  if (Settings().multipleFeedSupport)
                    CustomTextFutureButton(
                        onPressed: () async {
                          final roomId =
                              await client.createPrivateMinestrixProfile();
                          await room.setSpaceChild(roomId);
                        },
                        text: "Create a private MinesTRIX room",
                        color: Theme.of(context).primaryColor,
                        icon: Icons.person_add),
                  if (Settings().multipleFeedSupport)
                    CustomTextFutureButton(
                        onPressed: () async {
                          final roomId =
                              await client.createPublicMinestrixProfile();
                          await room.setSpaceChild(roomId);
                        },
                        text: "Create a public MinesTRIX room",
                        color: Theme.of(context).primaryColor,
                        icon: Icons.public)
                ],
              ),
            ],
          );

          final rightBar = Column(
            children: [
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
                      await widget.profile.r.removeSpaceChild(room.id);
                    },
                    onRemoveFromProfile: () async {
                      await widget.profile.r.removeSpaceChild(room.id);
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

          return Row(
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
          );
        })
      ],
    );
  }
}

class NoProfileSpaceFound extends StatelessWidget {
  const NoProfileSpaceFound({
    Key? key,
    required this.client,
  }) : super(key: key);

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
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
                    await ProfileSpace.createProfileSpace(client);
                  },
                  color: Theme.of(context).primaryColor,
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
      {Key? key, required this.onLeave, this.onRemoveFromProfile})
      : super(key: key);
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
              Text((r.name),
                  style: const TextStyle(fontWeight: FontWeight.bold))
            ]),
        subtitle: RoomInfo(r: r),
        trailing: PopupMenuButton<String>(
            itemBuilder: (_) => [
                  PopupMenuItem(
                      value: "settings",
                      child: Row(children: const [
                        Icon(
                          Icons.settings,
                        ),
                        SizedBox(width: 10),
                        Text("Settings"),
                      ])),
                  if (onRemoveFromProfile != null)
                    PopupMenuItem(
                      value: "remove",
                      child: Row(children: const [
                        Icon(Icons.remove),
                        SizedBox(width: 10),
                        Text("Remove from profile")
                      ]),
                    ),
                  PopupMenuItem(
                      value: "leave",
                      child: Row(
                        children: const [
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
    Key? key,
    required this.r,
  }) : super(key: key);

  final Room r;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (r.topic != "")
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(r.topic),
          ),
        if (r.joinRules == JoinRules.invite)
          Row(
            children: const [
              Icon(Icons.person),
              SizedBox(width: 10),
              Text("Private"),
            ],
          ),
        if (r.joinRules == JoinRules.knock)
          Row(
            children: const [
              Icon(Icons.person),
              SizedBox(width: 10),
              Text("Knock"),
            ],
          ),
        if (r.joinRules == JoinRules.public)
          Row(
            children: const [
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
          Row(
            children: const [
              Icon(Icons.verified_user),
              SizedBox(width: 10),
              Text("Encrypted")
            ],
          ),
        if (!r.encrypted)
          Row(
            children: const [
              Icon(Icons.no_encryption),
              SizedBox(width: 10),
              Text("Not encrypted")
            ],
          ),
      ],
    );
  }
}
