import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/components/minesTrix/MinesTrixContactView.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserSelection.dart';
import 'package:minestrix/components/post/postView.dart';
import 'package:minestrix/components/post/postWriterModal.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrix/SMatrixRoom.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';

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
    List<User> participants = sroom.room.getParticipants();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) => Row(
        children: [
          if (constraints.maxWidth > 900)
            Flexible(
              flex: 2,
              child: StreamBuilder(
                  stream: sclient.onSync.stream,
                  builder: (context, _) => ListView.builder(
                      itemCount: participants.length + 1,
                      itemBuilder: (BuildContext context, int i) {
                        if (i < participants.length)
                          return MinesTrixContactView(user: participants[i]);

                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: MinesTrixButton(
                              label: "Add users",
                              icon: Icons.person_add,
                              onPressed: () async {
                                List<Profile> profiles =
                                    await Navigator.of(context)
                                        .push(MaterialPageRoute(
                                  builder: (_) => MinesTrixUserSelection(),
                                ));

                                profiles.forEach((Profile p) {
                                  print(p.displayName);
                                });
                              }),
                        );
                      })),
            ),
          Flexible(
            flex: 8,
            child: StreamBuilder(
                stream: sroom.room.onUpdate.stream,
                builder: (context, _) => ListView(
                      children: [
                        if (sroom.room.avatar != null)
                          Center(
                              child: MatrixUserImage(
                                  client: sclient,
                                  url: sroom.room.avatar,
                                  unconstraigned: true,
                                  rounded: false,
                                  maxHeight: 500)),
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 8.0),
                              child: H1Title(sroom.name),
                            ),
                            Padding(
                                padding: const EdgeInsets.all(15),
                                child: Row(children: [
                                  for (User user in sroom.room
                                      .getParticipants()
                                      .where((User u) =>
                                          u.membership == Membership.join))
                                    MatrixUserImage(
                                        client: sclient,
                                        url: user.avatarUrl,
                                        thumnail: true)
                                ])),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: PostWriterModal(sroom: sroom),
                        ),
                        for (Event e in sevents)
                          Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
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
                    )),
          ),
        ],
      ),
    );
  }
}
