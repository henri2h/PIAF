import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/account/accountCard.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/partials/users/userInfo.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';

class UserFriendsPage extends StatelessWidget {
  const UserFriendsPage({Key? key, required this.sroom}) : super(key: key);

  final MinestrixRoom sroom;

  @override
  Widget build(BuildContext context) {
    MinestrixClient? sclient = Matrix.of(context).sclient;
    return ListView(
      children: [
        if(sroom.userID != null)
        FutureBuilder<Profile>(
            future: sroom.room.client.getProfileFromUserId(sroom.userID!),
            builder: (context, snap) {
              if (!snap.hasData) return CircularProgressIndicator();
              return UserInfo(profile: snap.data!);
            }),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child:
              H2Title((sroom.user?.displayName ?? sroom.userID ?? "null") + " friends"),
        ),
        Wrap(alignment: WrapAlignment.center, children: [
          for (User user in sroom.room.getParticipants().where((User u) =>
              u.membership == Membership.join &&
              u.id != sclient!.userID &&
              u.id != sroom.userID))
            AccountCard(user: user),
        ]),
      ],
    );
  }
}
