import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/screens/chat/addUser.dart';

class ConversationSettings extends StatelessWidget {
  ConversationSettings({Key key, this.roomId}) : super(key: key);
  final String roomId;

  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    final Room room = sclient.getRoomById(roomId);
    return ListView(
      children: [
        H1Title(room.name),
        H2Title("Users"),
        for (User u in room.getParticipants())
          ListTile(
              title: Text(u.displayName),
              leading: MinesTrixUserImage(url: u.avatarUrl, thumnail: true),
              subtitle: Text(u.id)),
        Padding(
          padding: const EdgeInsets.all(30.0),
          child: MinesTrixButton(
              label: "User",
              icon: Icons.person_add,
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) => FollowUser(context)));
              }),
        )
      ],
    );
  }
}
