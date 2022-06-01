import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:minestrix/partials/components/account/account_card.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/partials/users/userInfo.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';

class UserFriendsPage extends StatelessWidget {
  const UserFriendsPage({Key? key, required this.room}) : super(key: key);

  final Room room;

  @override
  Widget build(BuildContext context) {
    Client? sclient = Matrix.of(context).client;
    return ListView(
      children: [
        if (room.creatorId != null)
          FutureBuilder<Profile>(
              future: room.client.getProfileFromUserId(room.creatorId!),
              builder: (context, snap) {
                if (!snap.hasData) return CircularProgressIndicator();
                return UserInfo(profile: snap.data!);
              }),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: H2Title(
              (room.creator?.displayName ?? room.creatorId ?? "null") +
                  " friends"),
        ),
        Wrap(alignment: WrapAlignment.center, children: [
          for (User user in room.getParticipants().where((User u) =>
              u.membership == Membership.join &&
              u.id != sclient.userID &&
              u.id != room.creatorId))
            AccountCard(user: user),
        ]),
      ],
    );
  }
}
