import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/account/MinesTrixContactView.dart';
import 'package:minestrix/partials/components/buttons/MinesTrixButton.dart';
import 'package:minestrix/partials/components/buttons/customFutureButton.dart';
import 'package:minestrix/partials/components/layouts/customHeader.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/partials/post/postView.dart';
import 'package:minestrix/partials/post/postWriterModal.dart';
import 'package:minestrix/partials/users/MinesTrixUserSelection.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';
import 'package:minestrix_chat/partials/custom_list_view.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';
import 'package:minestrix_chat/view/matrix_chat_page.dart';

class GroupPage extends StatefulWidget {
  GroupPage({Key? key, this.sroom}) : super(key: key);
  final MinestrixRoom? sroom;

  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;
    MinestrixRoom sroom = widget.sroom!;
    List<Event> sevents =
        sclient.getSRoomFilteredEvents(sroom.timeline!) as List<Event>;
    List<User> participants = sroom.room.getParticipants();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) => Row(
        children: [
          if (constraints.maxWidth > 900)
            SizedBox(
              width: 280,
              child: Column(
                children: [
                  Flexible(
                    flex: 2,
                    child: StreamBuilder(
                        stream: sclient.onSync.stream,
                        builder: (context, _) => FutureBuilder<List<User>>(
                            future: sroom.room.requestParticipants(),
                            builder: (context, snap) {
                              if (snap.hasData == false)
                                return CircularProgressIndicator();

                              participants = snap.data!;
                              return ListView(
                                children: [
                                  for (User p in participants.where((User u) =>
                                      u.membership == Membership.join))
                                    MinesTrixContactView(user: p),
                                  if (participants.indexWhere((User u) =>
                                          u.membership == Membership.invite) !=
                                      -1)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        H2Title("Invited"),
                                        for (User p in participants.where(
                                            (User u) =>
                                                u.membership ==
                                                Membership.invite))
                                          MinesTrixContactView(user: p),
                                      ],
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: MinesTrixButton(
                                        label: "Add users",
                                        icon: Icons.person_add,
                                        onPressed: () async {
                                          List<Profile>? profiles =
                                              await Navigator.of(context).push(
                                                  MaterialPageRoute<
                                                      List<Profile>>(
                                            builder: (_) =>
                                                MinesTrixUserSelection(),
                                          ));

                                          profiles?.forEach((Profile p) async {
                                            await sroom.room.invite(p.userId);
                                          });
                                          participants = await sroom.room
                                              .requestParticipants();
                                          setState(() {});
                                        }),
                                  )
                                ],
                              );
                            })),
                  ),
                  CustomFutureButton(
                      icon: Icon(Icons.chat,
                          color: Theme.of(context).colorScheme.onPrimary),
                      color: Theme.of(context).primaryColor,
                      children: [
                        Text("Open chat",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color:
                                    Theme.of(context).colorScheme.onPrimary)),
                        if (widget.sroom?.room.lastEvent?.text != null)
                          Text(widget.sroom!.room.lastEvent!.text,
                              maxLines: 2,
                              style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary)),
                      ],
                      onPressed: () async {
                        showDialog(
                            context: context,
                            builder: (context) => Dialog(
                                child: MatrixChatPage(
                                    roomId: widget.sroom!.room.id,
                                    client: sclient)));
                      }),
                ],
              ),
            ),
          Flexible(
            flex: 8,
            child: StreamBuilder(
                stream: sroom.room.onUpdate.stream,
                builder: (context, _) => CustomListViewWithEmoji(
                    itemCount: sevents.length + 1,
                    itemBuilder: (BuildContext c, int i,
                        void Function(Offset, Event) onReact) {
                      if (i == 0) {
                        return Column(children: [
                          CustomHeader(sroom.name),
                          if (sroom.room.avatar != null)
                            Center(
                                child: MatrixImageAvatar(
                                    client: sclient,
                                    url: sroom.room.avatar,
                                    unconstraigned: true,
                                    shape: MatrixImageAvatarShape.none,
                                    maxHeight: 500)),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: PostWriterModal(sroom: sroom),
                          ),
                        ]);
                      }

                      return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 2, horizontal: 12),
                          child: Post(
                              event: sevents[i - 1],
                              onReact: (e) => onReact(e, sevents[i - 1])));
                    })),
          )
        ],
      ),
    );
  }
}
