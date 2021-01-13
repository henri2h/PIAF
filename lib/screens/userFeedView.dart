import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/accountCard.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/components/post/postView.dart';
import 'package:minestrix/global/helpers/NavigationHelper.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/screens/debugVue.dart';
import 'package:minestrix/screens/settings.dart';

class UserFeedView extends StatelessWidget {
  const UserFeedView({Key key, @required this.userId}) : super(key: key);
  final String userId;
  Widget buildPage(SMatrixRoom sroom, List<Event> sevents) {
    return StreamBuilder(
        stream: sroom.room.onUpdate.stream,
        builder: (context, _) => ListView(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    H1Title("User feed"),
                    Row(
                      children: [
                        IconButton(
                            icon: Icon(Icons.bug_report),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => Scaffold(
                                      appBar:
                                          AppBar(title: Text("Debug time !!")),
                                      body: DebugView())));
                            }),
                        IconButton(
                            icon: Icon(Icons.settings),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => Scaffold(
                                      appBar: AppBar(title: Text("Settings")),
                                      body: SettingsView())));
                            }),
                      ],
                    ),
                  ],
                ),
                Stack(
                  children: [
                    Center(
                        child: MinesTrixUserImage(
                            url: sroom.room.avatar,
                            unconstraigned: true,
                            rounded: false,
                            maxHeight: 500)),
                    Container(
                      // alignment: Alignment.bottomCenter,
                      padding:
                          const EdgeInsets.only(left: 40, right: 40, top: 200),
                      child: UserInfo(user: sroom.user),
                    ),
                  ],
                ),
                Padding(
                    padding: const EdgeInsets.all(15),
                    child: FriendsView(sroom: sroom)),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8.0),
                  child: H2Title("Posts"),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 80),
                  child: MinesTrixButton(
                      onPressed: () {
                        NavigationHelper.navigateToWritePost(context, sroom);
                      },
                      label: "Write post on " +
                          sroom.user.displayName +
                          " timeline",
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

  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    String roomId = sclient.userIdToRoomId[userId];
    SMatrixRoom sroom = sclient.srooms[roomId];

    if (sroom != null) {
      List<Event> sevents = sclient.getSRoomFilteredEvents(sroom.timeline);
      return buildPage(sroom, sevents);
    } else {
      return FutureBuilder<Profile>(
          future: sclient.getProfileFromUserId(userId),
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
            p.userId = userId; // fix a nasty bug :(

            return Container(
                child: Column(children: [
              Container(
                // alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.only(left: 40, right: 40, top: 200),
                child: UserInfo(profile: p),
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
  const FriendsView({
    Key key,
    @required this.sroom,
  }) : super(key: key);

  final SMatrixRoom sroom;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: H2Title("Friends"),
        ),
        Center(
          child: Wrap(alignment: WrapAlignment.center, children: [
            for (User user in sroom.room
                .getParticipants()
                .where((User u) => u.membership == Membership.join))
              AccountCard(user: user),
          ]),
        ),
      ],
    );
  }
}

class UserInfo extends StatelessWidget {
  const UserInfo({Key key, this.user, this.profile}) : super(key: key);

  final Profile profile;
  final User user;

  @override
  Widget build(BuildContext context) {
    String userId = user?.id;
    String displayName = user?.displayName;
    Uri avatarUrl = user?.avatarUrl;

    if (profile != null) {
      userId = profile.userId;
      displayName = profile.displayname;
      avatarUrl = profile.avatarUrl;
    }

    return Card(
      elevation: 15,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Stack(children: [
              Align(
                alignment: Alignment.topRight,
                child:
                    IconButton(icon: Icon(Icons.more_horiz), onPressed: () {}),
              ),
              Center(
                  child: MinesTrixUserImage(
                      url: avatarUrl, width: 200, height: 200))
            ]),
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
