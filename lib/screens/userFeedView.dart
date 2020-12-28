import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/accountCard.dart';
import 'package:minestrix/components/pageTitle.dart';
import 'package:minestrix/components/postView.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';

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
                  PageTitle("User feed"),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: UserInfo(user: sroom.user),
                  ),
                  Padding(
                      padding: const EdgeInsets.all(15),
                      child: FriendsView(sroom: sroom)),
                  for (Event e in sevents)
                    Column(
                      children: [
                        Post(event: e),
                        Divider(
                          indent: 25,
                          endIndent: 25,
                          thickness: 0.5,
                        ),
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
    return Row(
      children: [
        CircleAvatar(
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
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.displayName,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            Text(user.id, style: TextStyle(fontSize: 20)),
          ],
        ),
      ],
    );
  }
}
