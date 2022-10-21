import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/buttons/custom_text_future_button.dart';
import 'package:minestrix/partials/components/layouts/custom_header.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/partials/chat/settings/conv_settings_card.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/utils/profile_space.dart';
import 'package:minestrix_chat/utils/room_feed_extension.dart';
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
        stream: client.onSync.stream,
        builder: (context, _) {
          ProfileSpace? profile = ProfileSpace.getProfileSpace(client);

          final rooms = client.srooms
              .where((sroom) =>
                  sroom.creatorId == client.userID &&
                  sroom.feedType == FeedRoomType.user)
              .toSet();

          return ListView(
            children: [
              const CustomHeader(title: "Your profiles"),
              profile == null
                  ? NoProfileSpaceFound(client: client)
                  : Column(
                      children: [
                        ProfileSpaceCard(profile: profile),
                        for (SpaceChild s in profile.r.spaceChildren.where(
                            (element) =>
                                element.roomId != null &&
                                client.getRoomById(element.roomId!) == null))
                          Padding(
                            padding: const EdgeInsets.only(left: 80.0),
                            child: ListTile(
                                leading: const Icon(Icons.error),
                                title: Text("could not open ${s.roomId!}"),
                                trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      await profile.removeSpaceChild(s.roomId!);
                                      setState(() {});
                                    })),
                          )
                      ],
                    ),
              for (Room room in rooms)
                Builder(builder: (context) {
                  final hasBeenAdded = profile != null &&
                      profile.r.spaceChildren.indexWhere(
                              (SpaceChild sc) => sc.roomId == room.id) !=
                          -1;
                  return SwitchListTile(
                    onChanged: profile != null
                        ? (bool value) async {
                            if (value) {
                              await profile.r.setSpaceChild(room.id);
                            } else {
                              await profile.r.removeSpaceChild(room.id);
                            }
                          }
                        : null,
                    value: hasBeenAdded,
                    title: Column(
                      children: [
                        RoomProfileListTile(room, onLeave: () async {
                          if (hasBeenAdded) {
                            await profile?.r.removeSpaceChild(room.id);
                          }
                          setState(() {});
                        }),
                      ],
                    ),
                  );
                }),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    if (profile != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CustomTextFutureButton(
                            onPressed: () async {
                              await profile.createStoriesRoom();
                              setState(() {});
                            },
                            text: "Create stories room",
                            expanded: false,
                            icon: const Icon(Icons.add_a_photo)),
                      ),
                    if (Settings().multipleFeedSupport)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CustomTextFutureButton(
                            onPressed: () async {
                              final roomId =
                                  await client.createPrivateMinestrixProfile();
                              await profile?.r.setSpaceChild(roomId);
                            },
                            text: "Create a private MinesTRIX room",
                            expanded: false,
                            icon: const Icon(Icons.person_add)),
                      ),
                    if (Settings().multipleFeedSupport)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CustomTextFutureButton(
                            onPressed: () async {
                              final roomId =
                                  await client.createPublicMinestrixProfile();
                              await profile?.r.setSpaceChild(roomId);
                            },
                            text: "Create a public MinesTRIX room",
                            expanded: false,
                            icon: const Icon(Icons.public)),
                      )
                  ],
                ),
              ),
            ],
          );
        });
  }
}

class ProfileSpaceCard extends StatelessWidget {
  const ProfileSpaceCard({
    Key? key,
    required this.profile,
  }) : super(key: key);

  final ProfileSpace profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: MatrixImageAvatar(
                  url: profile.r.avatar,
                  client: profile.r.client,
                  backgroundColor: Theme.of(context).primaryColor,
                  defaultText: profile.r.name,
                  width: 80,
                  height: 80),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.r.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(profile.r.topic),
                  Card(
                      color: Theme.of(context).primaryColor,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(profile.r.canonicalAlias,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            )),
                      )),
                  if (profile.r.joinRules == JoinRules.public)
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
                RoomSettingsPage.show(context: context, room: profile.r)),
      ),
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
  const RoomProfileListTile(this.r, {Key? key, required this.onLeave})
      : super(key: key);
  final Room r;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text((r.name),
                  style: const TextStyle(fontWeight: FontWeight.bold))
            ]),
        subtitle: Column(
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
        ),
        trailing: PopupMenuButton<String>(
            itemBuilder: (_) => [
                  PopupMenuItem(
                      value: "settings",
                      child: Row(children: const [
                        Icon(
                          Icons.settings,
                        ),
                        SizedBox(width: 10),
                        Text("Settings", style: TextStyle()),
                      ])),
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
                  await showDialog(
                      context: context,
                      builder: (context) => Dialog(
                          child: ConvSettingsCard(
                              room: r,
                              onClose: () => Navigator.of(context).pop())));
                  break;
                case "leave":
                  await r.leave();
                  onLeave();
                  break;
                default:
              }
            }),
        onTap: () {
          context.navigateTo(UserViewRoute(mroom: r));
        });
  }
}
