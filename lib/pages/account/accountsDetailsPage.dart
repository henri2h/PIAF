import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/uri_extension.dart';
import 'package:matrix/src/utils/space_child.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/partials/components/customFutureButton.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';
import 'package:minestrix_chat/utils/room_profile.dart';
import 'package:minestrix_chat/partials/stories_circle.dart';

class AccountsDetailsPage extends StatefulWidget {
  const AccountsDetailsPage({Key? key}) : super(key: key);

  @override
  _AccountsDetailsPageState createState() => _AccountsDetailsPageState();
}

class _AccountsDetailsPageState extends State<AccountsDetailsPage> {
  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;

    RoomProfile? profile = RoomProfile.getProfileRoom(sclient);

    return ListView(
      children: [
        H1Title("Accounts"),
        if (profile == null)
          Padding(
            padding: const EdgeInsets.all(25),
            child: CustomFutureButton(
                onPressed: () async {
                  await RoomProfile.createProfileRoom(sclient);
                  setState(() {});
                },
                text: "Create profile",
                icon: Icon(Icons.create)),
          ),
        if (profile != null)
          for (SpaceChild s in profile.spaceChildren)
            Builder(builder: (context) {
              if (s.roomId == false) return Icon(Icons.error);

              return Builder(builder: (context) {
                Room? r = sclient.getRoomById(s.roomId!);
                if (r == null) return Icon(Icons.error);

                if (r.getState("m.room.create")?.content["type"] ==
                    "msczzzz.stories.stories_room")
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        StorieCircle(room: r),
                        StorieCircle(room: r, dot: true),
                      ],
                    ),
                  );

                return RoomProfileListTile(r);
              });
            }),
        for (MinestrixRoom sroom in sclient.srooms.values.where((sroom) =>
            sroom.user.id == sclient.userID &&
            sroom.roomType == SRoomType.UserRoom &&
            (profile == null ||
                profile.spaceChildren.indexWhere(
                        (SpaceChild sc) => sc.roomId == sroom.room.id) ==
                    -1)))
          ListTile(
              leading: CircleAvatar(
                backgroundImage: sroom.user.avatarUrl == null
                    ? null
                    : NetworkImage(
                        sroom.user.avatarUrl!
                            .getThumbnail(
                              sclient,
                              width: 64,
                              height: 64,
                            )
                            .toString(),
                      ),
              ),
              title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text((sroom.user.displayName ?? sroom.user.id),
                        style: TextStyle(fontWeight: FontWeight.bold))
                  ]),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sroom.room.topic != "")
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(sroom.room.topic),
                    ),
                  if (sroom.room.joinRules == JoinRules.invite)
                    Row(
                      children: [
                        Icon(Icons.person),
                        SizedBox(width: 10),
                        Text("Private"),
                      ],
                    ),
                  if (sroom.room.joinRules == JoinRules.public)
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
                      Text(sroom.room.summary.mJoinedMemberCount.toString() +
                          " followers"),
                    ],
                  ),
                  if (sroom.room.encrypted)
                    Row(
                      children: [
                        Icon(Icons.verified_user),
                        SizedBox(width: 10),
                        Text("Encrypted")
                      ],
                    ),
                  if (!sroom.room.encrypted)
                    Row(
                      children: [
                        Icon(Icons.no_encryption),
                        SizedBox(width: 10),
                        Text("Not encrypted")
                      ],
                    ),
                  if (profile != null &&
                      profile.spaceChildren.contains(
                              (SpaceChild sc) => sc.roomId == sroom.room.id) ==
                          false)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CustomFutureButton(
                          onPressed: () async {
                            await profile.setSpaceChild(sroom.room.id);
                          },
                          text: "Add to profile list",
                          icon: Icon(Icons.add)),
                    )
                ],
              ),
              trailing: PopupMenuButton<String>(
                  itemBuilder: (_) => [
                        PopupMenuItem(
                            child: Row(
                              children: [
                                Icon(Icons.delete_forever, color: Colors.red),
                                SizedBox(width: 10),
                                Text("Leave",
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                            value: "leave")
                      ],
                  icon: Icon(Icons.more_horiz),
                  onSelected: (String action) async {
                    switch (action) {
                      case "leave":
                        await sroom.room.leave();
                        setState(() {
                          sclient.srooms.remove(sroom);
                        });
                        break;
                      default:
                    }
                  }),
              onTap: () {
                context.pushRoute(UserFeedRoute(sroom: sroom));
              }),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              if (profile != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CustomFutureButton(
                      onPressed: () async {
                        await profile.createStoriesRoom();
                        setState(() {});
                      },
                      text: "Create stories room",
                      icon: Icon(Icons.photo)),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomFutureButton(
                    onPressed: () async {},
                    text: "Create a public MinesTRIX room",
                    icon: Icon(Icons.person_add)),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class RoomProfileListTile extends StatelessWidget {
  const RoomProfileListTile(this.r, {Key? key}) : super(key: key);
  final Room r;

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text((r.name), style: TextStyle(fontWeight: FontWeight.bold))
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
            onSelected: (String action) async {
              switch (action) {
                case "leave":
                  await r.leave();
                  /*setState(() {
                                sclient.srooms.remove(r);
                              }*/
                  break;
                default:
              }
            }),
        onTap: () {
          // context.pushRoute(UserFeedRoute(sroom: r));
        });
  }
}
