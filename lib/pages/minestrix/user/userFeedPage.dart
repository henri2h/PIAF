import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/components/post/postView.dart';
import 'package:minestrix/components/post/postWriterModal.dart';
import 'package:minestrix/partials/users/userFriendsCard.dart';
import 'package:minestrix/partials/users/userInfo.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';
import 'package:minestrix_chat/view/matrix_chat_page.dart';
import 'package:minestrix_chat/view/matrix_chats_page.dart';

class UserFeedPage extends StatefulWidget {
  const UserFeedPage({Key? key, this.userId, this.sroom})
      : assert(userId != null || sroom != null),
        super(key: key);

  final String? userId;
  final MinestrixRoom? sroom;

  @override
  _UserFeedPageState createState() => _UserFeedPageState();
}

class _UserFeedPageState extends State<UserFeedPage> {
  bool isUserPage = false;
  bool requestingHistory = false;

  Widget buildPage(
      MinestrixClient sclient, MinestrixRoom sroom, Iterable<Event> sevents) {
    return LayoutBuilder(
      builder: (context, constraints) => StreamBuilder(
          stream: sroom.room.onUpdate.stream,
          builder: (context, _) => ListView(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child:
                              H1Title(isUserPage ? "My account" : "User feed")),
                      if (isUserPage)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 20),
                          child: Row(
                            children: [
                              IconButton(
                                  icon: Icon(Icons.settings),
                                  onPressed: () {
                                    context.navigateTo(SettingsRoute());
                                  }),
                            ],
                          ),
                        ),
                    ],
                  ),

                  UserInfo(
                      user: sroom.user,
                      avatar: sroom.room.avatar?.getDownloadLink(sclient)),

                  if (constraints.maxWidth <= 900)
                    Column(
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(15),
                            child: UserFriendsCard(sroom: sroom)),
                        MaterialButton(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("See all friends"),
                            ),
                            onPressed: () {
                              if (isUserPage) {
                                context.navigateTo(FriendsRoute());
                              } else {
                                context
                                    .navigateTo(UserFriendsRoute(sroom: sroom));
                              }
                            })
                      ],
                    ),

                  // feed

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (constraints.maxWidth > 900)
                        Flexible(
                          flex: 4,
                          child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                children: [
                                  UserFriendsCard(sroom: sroom),
                                  MaterialButton(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text("See all friends"),
                                      ),
                                      onPressed: () {
                                        if (isUserPage) {
                                          context.navigateTo(FriendsRoute());
                                        } else {
                                          context.navigateTo(
                                              UserFriendsRoute(sroom: sroom));
                                        }
                                      })
                                ],
                              )),
                        ),
                      Flexible(
                        flex: 9,
                        fit: FlexFit.loose,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 8.0),
                              child: H2Title("Posts"),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: PostWriterModal(sroom: sclient.userRoom),
                            ),
                            for (Event e in sevents)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Post(event: e),
                              ),
                            if (sevents.length == 0 ||
                                sevents.last.type != EventTypes.RoomCreate)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: MaterialButton(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          if (requestingHistory)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 10),
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          Text("Load more posts"),
                                        ],
                                      ),
                                    ),
                                    onPressed: () async {
                                      if (requestingHistory == false) {
                                        setState(() {
                                          requestingHistory = true;
                                        });
                                        await sroom.room
                                            .requestHistory(historyCount: 50);
                                        setState(() {
                                          requestingHistory = false;
                                        });
                                      }
                                    }),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;

    MinestrixRoom? sroom = widget.sroom;

    if (sroom == null) {
      String? roomId = sclient.userIdToRoomId[widget.userId!];
      if (roomId != null) sroom = sclient.srooms[roomId];
    }

    // check if the userId given is the same one as the user
    if (widget.userId == sclient.userID) isUserPage = true;

    User? user_in = sclient.userRoom!.room.getParticipants().firstWhereOrNull(
        (User u) =>
            (u.id == widget.userId)); // check if the user is following us

    if (sroom != null) {
      Iterable<Event> sevents =
          sclient.getSRoomFilteredEvents(sroom.timeline!, eventTypesFilter: [
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
      return buildPage(sclient, sroom, sevents);
    } else {
      return FutureBuilder<Profile>(
          future: sclient.getProfileFromUserId(widget.userId!),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData == false) {
              return CircularProgressIndicator();
            }
            Profile p = snapshot.data;
            p.userId = widget.userId!; // fix a nasty bug :(

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
                                sclient.getDirectChatFromUserId(widget.userId!);
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
