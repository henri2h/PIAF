import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../../matrix/matrix_user_item.dart';
import '../user/matrix_user_info_dialog.dart';
import '../user/matrix_user_powerlevel_info_card.dart';
import '../user/user_selector_dialog.dart';
import 'items/conv_setting_back_button.dart';

class ConvSettingsUsers extends StatefulWidget {
  final Room room;
  const ConvSettingsUsers({Key? key, required this.room}) : super(key: key);

  @override
  ConvSettingsUsersState createState() => ConvSettingsUsersState();
}

class ConvSettingsUsersState extends State<ConvSettingsUsers> {
  Future<void> inviteUsers() async {
    List<String>? profiles =
        await MinesTrixUserSelection.show(context, widget.room);

    profiles?.forEach((String userId) async {
      await widget.room.invite(userId);
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;

    return FutureBuilder<List<User>>(
        future: room.requestParticipants(),
        initialData: room.getParticipants(),
        builder: (context, snap) {
          List<User>? users = snap.data;

          return Column(
            children: [
              Row(
                children: const [
                  ConvSettingsBackButton(),
                  Text("Users",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              ElevatedButton(
                  onPressed: inviteUsers,
                  child: Row(
                    children: const [
                      Icon(Icons.person_add),
                      SizedBox(width: 8),
                      Text("Invite"),
                    ],
                  )),
              !snap.hasData
                  ? const CircularProgressIndicator()
                  : Expanded(
                      child: ListView.builder(
                          itemCount: users?.length,
                          itemBuilder: (context, int i) {
                            User u = users![i];
                            return MaterialButton(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                minWidth: 0,
                                padding: EdgeInsets.zero,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: MatrixUserItem(
                                          name: u.displayName,
                                          userId: u.senderId,
                                          client: room.client,
                                          avatarUrl: u.avatarUrl,
                                          subtitle:
                                              MatrixUserPowerLevelInfoCard(
                                                  user: u)),
                                    ),
                                    if (u.canKick || u.canBan)
                                      PopupMenuButton<String>(
                                          itemBuilder: (_) => [
                                                if (u.canKick)
                                                  PopupMenuItem(
                                                      value: "kick",
                                                      child: Row(
                                                        children: const [
                                                          Icon(Icons
                                                              .person_remove),
                                                          SizedBox(width: 10),
                                                          Text("Kick"),
                                                        ],
                                                      )),
                                                if (u.canBan)
                                                  PopupMenuItem(
                                                      value: "ban",
                                                      child: Row(
                                                        children: const [
                                                          Icon(
                                                              Icons
                                                                  .delete_forever,
                                                              color:
                                                                  Colors.red),
                                                          SizedBox(width: 10),
                                                          Text("Ban",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .red)),
                                                        ],
                                                      ))
                                              ],
                                          icon: const Icon(Icons.more_horiz),
                                          onSelected: (String action) async {
                                            switch (action) {
                                              case "kick":
                                                await u.kick();
                                                break;
                                              case "ban":
                                                await u.ban();
                                                break;
                                              default:
                                            }
                                          })
                                  ],
                                ),
                                onPressed: () async {
                                  await Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              MatrixUserInfoDialog(user: u)));
                                });
                          }),
                    ),
            ],
          );
        });
  }
}
