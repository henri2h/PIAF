import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/uri_extension.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';

class AccountsDetailsPage extends StatefulWidget {
  const AccountsDetailsPage({Key? key}) : super(key: key);

  @override
  _AccountsDetailsPageState createState() => _AccountsDetailsPageState();
}

class _AccountsDetailsPageState extends State<AccountsDetailsPage> {
  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;

    return ListView(
      children: [
        H1Title("Accounts"),
        for (MinestrixRoom sroom in sclient.srooms.values.where((sroom) =>
            sroom.user.id == sclient.userID &&
            sroom.roomType == SRoomType.UserRoom))
          ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    sroom.user.avatarUrl == null
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
                    Text(sroom.user.displayName!,
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
          padding: const EdgeInsets.all(30.0),
          child: OutlinedButton(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Text("Create a public account"),
              ),
              onPressed: () {}),
        ),
      ],
    );
  }
}
