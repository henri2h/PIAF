import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/accountCard.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/components/post/postView.dart';
import 'package:minestrix/components/post/postWriterModal.dart';
import 'package:minestrix/pages/settingsPage.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';
import 'package:minestrix_chat/view/matrix_chat_page.dart';
import 'package:minestrix_chat/view/matrix_chats_page.dart';

class UserFeedPage extends StatefulWidget {
  const UserFeedPage({Key? key, required this.userId}) : super(key: key);

  final String? userId;

  @override
  _UserFeedPageState createState() => _UserFeedPageState();
}

class _UserFeedPageState extends State<UserFeedPage> {
  bool isUserPage = false;

  Widget buildPage(MinestrixClient sclient, MinestrixRoom sroom, List<Event> sevents) {
    return LayoutBuilder(
      builder: (context, constraints) => StreamBuilder(
          stream: sroom.room!.onUpdate.stream,
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
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) => Scaffold(
                                                appBar: AppBar(
                                                    title: Text("Settings")),
                                                body: SettingsPage())));
                                  }),
                            ],
                          ),
                        ),
                    ],
                  ),

                  UserInfo(
                      user: sroom.user,
                      avatar: sroom.room!.avatar?.getDownloadLink(sclient)),

                  if (constraints.maxWidth <= 900)
                    Padding(
                        padding: const EdgeInsets.all(15),
                        child:
                            FriendsView(sroom: sroom, userID: widget.userId)),

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
                                  FriendsView(
                                      sroom: sroom, userID: widget.userId),
                                  MaterialButton(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text("See friends"),
                                      ),
                                      onPressed: () {})
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
                            /* Divider(
                                  indent: 25,
                                  endIndent: 25,
                                  thickness: 0.5,
                                ),*/
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
    String? roomId = sclient.userIdToRoomId[widget.userId!];
    MinestrixRoom? sroom = sclient.srooms[roomId!];

    if (widget.userId == sclient.userID) isUserPage = true;

    User? user_in = sclient.userRoom!.room!
        .getParticipants()
        .firstWhereOrNull((User u) => (u.id == widget.userId));

    if (sroom != null) {
      List<Event> sevents = sclient.getSRoomFilteredEvents(sroom.timeline!) as List<Event>;
      return buildPage(sclient, sroom, sevents);
    } else {
      return FutureBuilder<Profile>(
          future: sclient.getProfileFromUserId(widget.userId!),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData == false) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("ERROR !",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              );
            }
            Profile p = snapshot.data;
            p.userId = widget.userId!; // fix a nasty bug :(

            return Container(
                child: ListView(children: [
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
                              setState(() {
                                print("friend request sent");
                              });
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
            ]));
          });
    }
  }
}

class FriendsView extends StatelessWidget {
  const FriendsView({Key? key, required this.sroom, required this.userID})
      : super(key: key);

  final MinestrixRoom sroom;
  final String? userID;

  @override
  Widget build(BuildContext context) {
    MinestrixClient? sclient = Matrix.of(context).sclient;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: H2Title("Friends"),
        ),
        Wrap(alignment: WrapAlignment.spaceBetween, children: [
          for (User user in sroom.room!
              .getParticipants()
              .where((User u) =>
                  u.membership == Membership.join &&
                  u.id != sclient!.userID &&
                  u.id != userID)
              .take(8))
            AccountCard(user: user),
        ]),
      ],
    );
  }
}

class UserInfo extends StatelessWidget {
  const UserInfo({Key? key, this.user, this.profile, this.avatar})
      : super(key: key);

  final Profile? profile;
  final User? user;
  final Uri? avatar;

  @override
  Widget build(BuildContext context) {
    String? userId = user?.id;
    String? displayName = user?.displayName;
    Uri? avatarUrl = user?.avatarUrl;

    if (profile != null) {
      userId = profile!.userId;
      displayName = profile!.displayName;
      avatarUrl = profile!.avatarUrl;
    }

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      // small screens
      if (constraints.maxWidth < 800)
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            if (avatar != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 180),
                child: CachedNetworkImage(imageUrl: avatar.toString()),
              ),
            buildUserProfileDisplay(context, avatarUrl, displayName!, userId!),
          ],
        );

      // big screens
      return Container(
          decoration: avatar != null
              ? BoxDecoration(
                  image: DecorationImage(
                      image: CachedNetworkImageProvider(avatar.toString()),
                      fit: BoxFit.cover),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
            child: Align(
                alignment:
                    avatar != null ? Alignment.centerLeft : Alignment.center,
                child: buildUserProfileDisplay(
                    context, avatarUrl, displayName!, userId!)),
          ));
    });
  }

  Widget buildUserProfileDisplay(
      BuildContext context, Uri? avatarUrl, String displayName, String userId) {
    return Card(
      elevation: 15,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40.0),
        ),
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MatrixUserImage(
              client: Matrix.of(context).sclient,
              url: avatarUrl,
              width: 250,
              height: 250,
              thumnail: true,
              rounded: false,
              defaultIcon: Icon(Icons.person, size: 120),
            ),
            SizedBox(height: 10),
            Text(displayName,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            Text(userId,
                style: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context).textTheme.caption!.color)),
          ],
        ),
      ),
    );
  }
}
