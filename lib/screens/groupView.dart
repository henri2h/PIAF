import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/accountCard.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/components/post/postView.dart';
import 'package:minestrix/global/helpers/NavigationHelper.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrix/SMatrixRoom.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/screens/debugVue.dart';
import 'package:minestrix/screens/settings.dart';
import 'package:minestrix/screens/userFeedView.dart';

class GroupView extends StatefulWidget {
  GroupView({Key key, this.sroom}) : super(key: key);
  final SMatrixRoom sroom;

  @override
  _GroupViewState createState() => _GroupViewState();
}

class _GroupViewState extends State<GroupView> {
  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    SMatrixRoom sroom = widget.sroom;
    List<Event> sevents = sclient.getSRoomFilteredEvents(sroom.timeline);

    return StreamBuilder(
        stream: sroom.room.onUpdate.stream,
        builder: (context, _) => ListView(
              children: [
                Stack(
                  children: [
                    if (sroom.room.avatar != null)
                      Center(
                          child: MinesTrixUserImage(
                              url: sroom.room.avatar,
                              unconstraigned: true,
                              rounded: false,
                              maxHeight: 500)),
                  ],
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 8.0),
                      child: H1Title(sroom.room.name),
                    ),
                    Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(children: [
                          for (User user in sroom.room.getParticipants().where(
                              (User u) => u.membership == Membership.join))
                            MinesTrixUserImage(url: user.avatarUrl)
                        ])),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 80),
                  child: MinesTrixButton(
                      onPressed: () {
                        NavigationHelper.navigateToWritePost(context, sroom);
                      },
                      label: "Write post on " + sroom.room.name + " timeline",
                      icon: Icons.edit),
                ),
                for (Event e in sevents)
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Post(event: e),
                      ),
                      /* Divider(
                          indent: 25,
                          endIndent: 25,
                          thickness: 0.5,
                        ),*/
                    ],
                  ),
              ],
            ));
  }
}
