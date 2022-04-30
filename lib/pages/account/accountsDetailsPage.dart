import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/space_child.dart';
import 'package:minestrix/partials/components/buttons/customTextFutureButton.dart';
import 'package:minestrix/partials/components/layouts/customHeader.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrix_widget.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/partials/chat/settings/conv_settings_card.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';
import 'package:minestrix_chat/utils/profile_space.dart';
import 'package:minestrix_chat/utils/room_feed_extension.dart';

import '../../partials/components/buttons/customFutureButton.dart';

class AccountsDetailsPage extends StatefulWidget {
  const AccountsDetailsPage({Key? key}) : super(key: key);

  @override
  _AccountsDetailsPageState createState() => _AccountsDetailsPageState();
}

class _AccountsDetailsPageState extends State<AccountsDetailsPage> {
  @override
  Widget build(BuildContext context) {
    Client client = Matrix.of(context).client;

    ProfileSpace? profile = ProfileSpace.getProfileSpace(client);

    return ListView(
      children: [
        CustomHeader(title: "Profiles"),
        if (profile == null)
          Padding(
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
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16),
                          child: Icon(Icons.person, size: 50),
                        ),
                        Flexible(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 500),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("No user space found",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600)),
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
                          setState(() {});
                        },
                        children: [
                          Text("Create user space",
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary))
                        ],
                        color: Theme.of(context).primaryColor,
                        expanded: false,
                        icon: Icon(Icons.add,
                            color: Theme.of(context).colorScheme.onPrimary)),
                  ),
                ],
              ),
            ),
          ),
        if (profile != null)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: MatrixImageAvatar(
                            url: profile.r.avatar,
                            client: profile.r.client,
                            thumnail: true,
                            backgroundColor: Theme.of(context).primaryColor,
                            defaultText: profile.r.name,
                            width: 80,
                            height: 80),
                      ),
                      SizedBox(width: 4),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.r.name,
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(profile.r.topic),
                            Card(
                                color: Theme.of(context).primaryColor,
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(profile.r.canonicalAlias,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      )),
                                )),
                            if (profile.r.joinRules == JoinRules.public)
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Row(
                                  children: [
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
                      icon: Icon(Icons.edit),
                      onPressed: () async {
                        await showDialog(
                            context: context,
                            builder: (context) => Dialog(
                                child: ConvSettingsCard(
                                    room: profile.r,
                                    onClose: () =>
                                        Navigator.of(context).pop())));
                      }),
                ),
              ),
              for (SpaceChild s in profile.r.spaceChildren)
                Padding(
                  padding: const EdgeInsets.only(left: 80.0),
                  child: Builder(builder: (context) {
                    if (s.roomId == null) return Icon(Icons.error);

                    return Builder(builder: (context) {
                      Room? r = client.getRoomById(s.roomId!);
                      if (r == null)
                        return ListTile(
                            leading: Icon(Icons.error),
                            title: Text("could not open " + s.roomId!),
                            trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () async {
                                  await profile.removeSpaceChild(s.roomId!);
                                  setState(() {});
                                }));

                      return RoomProfileListTile(r, onLeave: () {
                        setState(() {});
                      });
                    });
                  }),
                ),
            ],
          ),
        for (Room room in client.srooms.where((sroom) =>
            sroom.userID == client.userID &&
            sroom.type == FeedRoomType.user &&
            (profile == null ||
                profile.r.spaceChildren
                        .indexWhere((SpaceChild sc) => sc.roomId == sroom.id) ==
                    -1)))
          Column(
            children: [
              RoomProfileListTile(room, onLeave: () => setState(() {})),
              if (profile != null &&
                  profile.r.spaceChildren
                          .contains((SpaceChild sc) => sc.roomId == room.id) ==
                      false)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CustomTextFutureButton(
                      onPressed: () async {
                        await profile.r.setSpaceChild(room.id);
                        setState(() {});
                      },
                      text: "Add to " + profile.r.name,
                      icon: Icon(Icons.add)),
                )
            ],
          ),
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
                      icon: Icon(Icons.add_a_photo)),
                ),
              if (Matrix.of(context).settings.multipleFeedSupport)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CustomTextFutureButton(
                      onPressed: () async {},
                      text: "Create a public MinesTRIX room",
                      expanded: false,
                      icon: Icon(Icons.person_add)),
                )
            ],
          ),
        ),
      ],
    );
  }
}

class RoomProfileListTile extends StatefulWidget {
  const RoomProfileListTile(this.r, {Key? key, required this.onLeave})
      : super(key: key);
  final Room r;
  final VoidCallback onLeave;
  @override
  _RoomProfileListTileState createState() => _RoomProfileListTileState();
}

class _RoomProfileListTileState extends State<RoomProfileListTile> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    Room r = widget.r;
    return ListTile(
        title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text((r.name), style: TextStyle(fontWeight: FontWeight.bold))
            ]),
        leading: _updating ? CircularProgressIndicator() : null,
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
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 10),
                  Text("Private"),
                ],
              ),
            if (r.joinRules == JoinRules.public)
              Row(
                children: [
                  Icon(Icons.public),
                  SizedBox(width: 10),
                  Text("Public"),
                ],
              ),
            Row(
              children: [
                Icon(Icons.people),
                SizedBox(width: 10),
                Text(r.summary.mJoinedMemberCount.toString() + " followers"),
              ],
            ),
            if (r.encrypted)
              Row(
                children: [
                  Icon(Icons.verified_user),
                  SizedBox(width: 10),
                  Text("Encrypted")
                ],
              ),
            if (!r.encrypted)
              Row(
                children: [
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
                      child: Row(children: [
                        Icon(
                          Icons.settings,
                        ),
                        SizedBox(width: 10),
                        Text("Settings", style: TextStyle()),
                      ]),
                      value: "settings"),
                  PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, color: Colors.red),
                          SizedBox(width: 10),
                          Text("Leave", style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      value: "leave")
                ],
            icon: Icon(Icons.more_horiz),
            onSelected: _updating
                ? null
                : (String action) async {
                    switch (action) {
                      case "settings":
                        await showDialog(
                            context: context,
                            builder: (context) => Dialog(
                                child: ConvSettingsCard(
                                    room: r,
                                    onClose: () =>
                                        Navigator.of(context).pop())));
                        break;
                      case "leave":
                        setState(() {
                          _updating = true;
                        });
                        await r.leave();

                        setState(() {
                          _updating = false;
                        });
                        widget.onLeave();
                        break;
                      default:
                    }
                  }),
        onTap: () {
          context.navigateTo(UserViewRoute(mroom: r));
        });
  }
}
