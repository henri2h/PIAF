import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/partials/users/userInfo.dart';
import 'package:minestrix/partials/users/userView.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';
import 'package:minestrix_chat/view/matrix_chat_page.dart';
import 'package:minestrix_chat/view/matrix_chats_page.dart';

class UserViewPage extends StatefulWidget {
  const UserViewPage({Key? key, this.userId, this.sroom})
      : assert(sroom != null && userId == null || sroom == null),
        super(key: key);

  final String? userId;
  final MinestrixRoom? sroom;

  @override
  _UserViewPageState createState() => _UserViewPageState();
}

class _UserViewPageState extends State<UserViewPage> {
  MinestrixRoom? sroom;
  String? userId;

  bool requestingHistory = false;

  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;

    sroom = widget.sroom;

    if (sroom == null) {
      userId = widget.userId ?? sclient.userID;

      String? roomId = sclient.userIdToRoomId[userId!];
      if (roomId != null) sroom = sclient.srooms[roomId];
    } else {
      userId = sroom!.user.id;
    }

    User? user_in = sclient.userRoom!.room.getParticipants().firstWhereOrNull(
        (User u) =>
            (u.id == widget.userId)); // check if the user is following us

    if (sroom != null) {
      Iterable<Event> sevents =
          sclient.getSRoomFilteredEvents(sroom!.timeline!, eventTypesFilter: [
        EventTypes.Message,
        EventTypes.Encrypted,
        EventTypes.RoomCreate,
        EventTypes.RoomAvatar,
        EventTypes.RoomMember
      ]).where((Event e) {
        if (e.type == EventTypes.RoomMember) {
          if (e.prevContent != null &&
              e.content["avatar_url"] != e.prevContent!["avatar_url"] &&
              e.senderId == sroom!.user.id) {
            // the room owner has changed it's profile picture
            return true;
          }
          return false;
        }
        return true;
      });
      return UserView(
        userID: userId!,
      );
    } else {
      return FutureBuilder<Profile>(
          future: sclient.getProfileFromUserId(userId!),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData == false) {
              return CircularProgressIndicator();
            }
            Profile p = snapshot.data;
            p.userId = userId!; // fix a nasty bug :(

            return ListView(children: [
              Container(
                // alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.only(left: 40, right: 40, top: 200),
                child: UserInfo(profile: p),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: Row(
                  children: [
                    if (user_in == null ||
                        (user_in.membership != Membership.join &&
                            user_in.membership != Membership.invite))
                      Flexible(
                        child: MinesTrixButton(
                            icon: Icons.person_add,
                            label: "Add to friends",
                            onPressed: () async {
                              await sclient.addFriend(p.userId);
                              setState(() {});
                            }),
                      ),
                    if (user_in != null &&
                        user_in.membership == Membership.invite)
                      Flexible(
                          child: MinesTrixButton(
                        icon: Icons.send,
                        label: "Friend request sent",
                        onPressed: null,
                      )),
                    if (user_in != null &&
                        user_in.membership == Membership.join)
                      Flexible(
                          child: MinesTrixButton(
                        icon: Icons.person,
                        label: "Friend",
                        onPressed: null,
                      )),
                    SizedBox(width: 30),
                    Flexible(
                      child: MinesTrixButton(
                          icon: Icons.message,
                          label: "Send message",
                          onPressed: () {
                            String? roomId =
                                sclient.getDirectChatFromUserId(userId!);
                            if (roomId != null) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          MatrixChatPage(
                                              roomId: roomId,
                                              client: sclient)));
                            } else {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          Scaffold(
                                              appBar: AppBar(
                                                  title: Text("Start chat")),
                                              body: MatrixChatsPage(
                                                  client: sclient))));
                            }
                          }),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 60, vertical: 100),
                child: Column(
                  children: [
                    Text("Your are not in this user friend list",
                        style: TextStyle(fontSize: 40)),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text("😧", style: TextStyle(fontSize: 40)),
                    ),
                    Text(
                        "Or he/she may not have a MINESTRIX account (yet), send him a message ;)",
                        style: TextStyle(fontSize: 20))
                  ],
                ),
              ),
            ]);
          });
    }
  }
}
