import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/space_child.dart';
import 'package:minestrix/partials/components/buttons/customFutureButton.dart';
import 'package:minestrix/partials/components/layouts/customHeader.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';
import 'package:minestrix_chat/utils/room_profile.dart';

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
        CustomHeader("Accounts"),
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
              if (s.roomId == null) return Icon(Icons.error);

              return Builder(builder: (context) {
                Room? r = sclient.getRoomById(s.roomId!);
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
        for (MinestrixRoom sroom in sclient.srooms.values.where((sroom) =>
            sroom.user.id == sclient.userID &&
            sroom.roomType == SRoomType.UserRoom &&
            (profile == null ||
                profile.spaceChildren.indexWhere(
                        (SpaceChild sc) => sc.roomId == sroom.room.id) ==
                    -1)))
          Column(
            children: [
              RoomProfileListTile(sroom.room, onLeave: () => setState(() {})),
              if (profile != null &&
                  profile.spaceChildren.contains(
                          (SpaceChild sc) => sc.roomId == sroom.room.id) ==
                      false)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CustomFutureButton(
                      onPressed: () async {
                        await profile.setSpaceChild(sroom.room.id);
                        setState(() {});
                      },
                      text: "Add to profile list",
                      icon: Icon(Icons.add)),
                )
            ],
          ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
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
                    MinestrixClient sclient = Matrix.of(context).sclient!;
                    switch (action) {
                      case "leave":
                        setState(() {
                          _updating = true;
                        });
                        await r.leave();
                        /* await r.client.onSync.stream.firstWhere((sync) =>
                            sync.rooms?.join?.containsKey(r.id) ?? false);*/

                        await sclient.updateAll();
                        setState(() {
                          _updating = false;
                        });
                        widget.onLeave();
                        break;
                      default:
                    }
                  }),
        onTap: () {
          MinestrixClient sclient = Matrix.of(context).sclient!;
          MinestrixRoom? _r = sclient.srooms[r.id];
          if (_r != null) context.navigateTo(UserViewRoute(mroom: _r));
        });
  }
}
