import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../../matrix/matrix_user_item.dart';
import '../user/selector/user_selector_dialog.dart';
import '../user/user_info_dialog.dart';
import '../user/user_powerlevel_info_card.dart';

class ConvSettingsUsers extends StatefulWidget {
  final Room room;
  const ConvSettingsUsers({super.key, required this.room});

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

          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text("Users"),
              forceMaterialTransparency: true,
              actions: [
                IconButton(
                    onPressed: inviteUsers, icon: const Icon(Icons.person_add))
              ],
            ),
            body: !snap.hasData
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
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
                                    subtitle: UserPowerLevelInfoCard(user: u)),
                              ),
                              if (u.canKick || u.canBan)
                                PopupMenuButton<String>(
                                    itemBuilder: (_) => [
                                          if (u.canKick)
                                            const PopupMenuItem(
                                                value: "kick",
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.person_remove),
                                                    SizedBox(width: 10),
                                                    Text("Kick"),
                                                  ],
                                                )),
                                          if (u.canBan)
                                            const PopupMenuItem(
                                                value: "ban",
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete_forever,
                                                        color: Colors.red),
                                                    SizedBox(width: 10),
                                                    Text("Ban",
                                                        style: TextStyle(
                                                            color: Colors.red)),
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
                            await Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => UserInfoDialog(user: u)));
                          });
                    }),
          );
        });
  }
}
