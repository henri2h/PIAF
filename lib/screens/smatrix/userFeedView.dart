import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/accountCard.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/components/post/postView.dart';
import 'package:minestrix/components/post/postWriterModal.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrix/SMatrixRoom.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/screens/chat/chatVue.dart';
import 'package:minestrix/screens/chat/chatsVue.dart';
import 'package:minestrix/screens/settings.dart';

class UserFeedView extends StatefulWidget {
  const UserFeedView({Key key, @required this.userId}) : super(key: key);

  final String userId;

  @override
  _UserFeedViewState createState() => _UserFeedViewState();
}

class _UserFeedViewState extends State<UserFeedView> {
  bool isUserPage = false;

  Widget buildPage(SClient sclient, SMatrixRoom sroom, List<Event> sevents) {
    return LayoutBuilder(
      builder: (context, constraints) => StreamBuilder(
          stream: sroom.room.onUpdate.stream,
          builder: (context, _) => ListView(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      H1Title(isUserPage ? "My account" : "User feed"),
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
                                                body: SettingsView())));
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
                              child: FriendsView(
                                  sroom: sroom, userID: widget.userId)),
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
                      if (constraints.maxWidth > 900)
                        Flexible(flex: 2, child: Container())
                    ],
                  ),
                ],
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    String roomId = sclient.userIdToRoomId[widget.userId];
    SMatrixRoom sroom = sclient.srooms[roomId];

    if (widget.userId == sclient.userID) isUserPage = true;

    User user_in = sclient.userRoom.room
        .getParticipants()
        .firstWhere((User u) => (u.id == widget.userId), orElse: () => null);

    if (sroom != null) {
      List<Event> sevents = sclient.getSRoomFilteredEvents(sroom.timeline);
      return buildPage(sclient, sroom, sevents);
    } else {
      return FutureBuilder<Profile>(
          future: sclient.getProfileFromUserId(widget.userId),
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
            p.userId = widget.userId; // fix a nasty bug :(

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
                            String roomId =
                                sclient.getDirectChatFromUserId(widget.userId);
                            if (roomId != null) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          ChatView(roomId: roomId)));
                            } else {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          Scaffold(
                                              appBar: AppBar(
                                                  title: Text("Start chat")),
                                              body: ChatsVue())));
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
  const FriendsView({Key key, @required this.sroom, @required this.userID})
      : super(key: key);

  final SMatrixRoom sroom;
  final String userID;

  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: H2Title("Friends"),
        ),
        Wrap(alignment: WrapAlignment.spaceBetween, children: [
          for (User user in sroom.room.getParticipants().where((User u) =>
              u.membership == Membership.join &&
              u.id != sclient.userID &&
              u.id != userID))
            AccountCard(user: user),
        ]),
      ],
    );
  }
}

class UserInfo extends StatelessWidget {
  const UserInfo({Key key, this.user, this.profile, this.avatar})
      : super(key: key);

  final Profile profile;
  final User user;
  final Uri avatar;

  @override
  Widget build(BuildContext context) {
    String userId = user?.id;
    String displayName = user?.displayName;
    Uri avatarUrl = user?.avatarUrl;

    if (profile != null) {
      userId = profile.userId;
      displayName = profile.displayName;
      avatarUrl = profile.avatarUrl;
    }

    /*
     Container(
                    foregroundDecoration: const BoxDecoration(
                      image: DecorationImage(
                          image: NetworkImage(
                              'https://p6.storage.canalblog.com/69/50/922142/85510911_o.png'),
                          fit: BoxFit.fill),
                    ),
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                          alignment: Alignment(-.2, 0),
                          image: NetworkImage(
                              'http://www.naturerights.com/blog/wp-content/uploads/2017/12/Taranaki-NR-post-1170x550.png'),
                          fit: BoxFit.cover),
                    ),
                    alignment: Alignment.bottomCenter,
                    padding: EdgeInsets.only(bottom: 20),
                    child: Text(
                      "Hello World",
                      style: Theme.of(context)
                          .textTheme
                          .display1
                          .copyWith(color: Colors.white),
                    ),
                  ),
                     */

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
            buildUserProfileDisplay(avatarUrl, displayName, userId),
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
                child: buildUserProfileDisplay(avatarUrl, displayName, userId)),
          ));
    });
  }

  Widget buildUserProfileDisplay(
      Uri avatarUrl, String displayName, String userId) {
    return Card(
      elevation: 15,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40.0),
        ),
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MinesTrixUserImage(
              url: avatarUrl,
              width: 250,
              height: 250,
              thumnail: true,
              rounded: false,
              defaultIcon: Icon(Icons.person, color: Colors.black, size: 120),
            ),
            SizedBox(height: 10),
            Text(displayName,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            Text(userId,
                style: TextStyle(fontSize: 20, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
