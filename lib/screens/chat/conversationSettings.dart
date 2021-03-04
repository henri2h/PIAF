import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/screens/smatrix/friends/addUser.dart';

class ConversationSettings extends StatelessWidget {
  ConversationSettings({Key key, this.room}) : super(key: key);
  final Room room;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Settings")),
        body: ListView(
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
                            builder: (BuildContext context) =>
                                AddUser(context)));
                  }),
            )
          ],
        ));
  }
}
