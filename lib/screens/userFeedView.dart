import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/accountCard.dart';
import 'package:minestrix/components/pageTitle.dart';
import 'package:minestrix/components/postView.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/screens/debugVue.dart';
import 'package:minestrix/screens/settings.dart';

class UserFeedView extends StatelessWidget {
  const UserFeedView({Key key, @required this.userId}) : super(key: key);
  final String userId;

  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    String roomId = sclient.userIdToRoomId[userId];
    SMatrixRoom sroom = sclient.srooms[roomId];

    List<Event> sevents = sclient.getSRoomFilteredEvents(sroom.timeline);
    if (sroom != null) {
      return StreamBuilder(
          stream: sroom.room.onUpdate.stream,
          builder: (context, _) => ListView(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PageTitle("User feed"),
                      Row(
                        children: [
                          IconButton(
                              icon: Icon(Icons.bug_report),
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => Scaffold(
                                        appBar: AppBar(
                                            title: Text("Debug time !!")),
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
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: UserInfo(user: sroom.user),
                  ),
                  Padding(
                      padding: const EdgeInsets.all(15),
                      child: FriendsView(sroom: sroom)),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: RaisedButton(
                      onPressed: () {},
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(80.0)),
                      padding: const EdgeInsets.all(0.0),
                      child: Ink(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              Color(0xFFd24800),
                              Color(0xFF0000a4),
                            ],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(80.0)),
                        ),
                        child: Container(
                          constraints: const BoxConstraints(
                              minWidth: 88.0,
                              minHeight:
                                  36.0), // min sizes for Material buttons
                          alignment: Alignment.center,
                          child: const Text('OK',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text("ERROR !",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
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
          padding: const EdgeInsets.all(8.0),
          child: Text("Friends",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        Wrap(children: [
          for (User user in sroom.room
              .getParticipants()
              .where((User u) => u.membership == Membership.join))
            AccountCard(user: user),
        ]),
      ],
    );
  }
}

class UserInfo extends StatelessWidget {
  const UserInfo({Key key, @required this.user}) : super(key: key);
  final User user;
  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
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
                child: CircleAvatar(
                  backgroundImage: user.avatarUrl == null
                      ? null
                      : NetworkImage(
                          user.avatarUrl.getThumbnail(
                            sclient,
                            width: 64,
                            height: 64,
                          ),
                        ),
                ),
              )
            ]),
            Text(user.displayName,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            Text(user.id,
                style: TextStyle(fontSize: 20, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
