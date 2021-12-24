import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/accountCard.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';

class UserFriendsCard extends StatelessWidget {
  const UserFriendsCard({Key? key, required this.sroom}) : super(key: key);

  final MinestrixRoom sroom;
  Future<List<User>> getUsers() async {
    return sroom.room.participantListComplete
        ? sroom.room.getParticipants()
        : await sroom.room.requestParticipants();
  }

  @override
  Widget build(BuildContext context) {
    MinestrixClient? sclient = Matrix.of(context).sclient;
    return FutureBuilder<List<User>>(
        future: getUsers(),
        initialData: sroom.room.getParticipants(),
        builder: (context, snap) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: H2Title("Friends"),
              ),
              Wrap(alignment: WrapAlignment.spaceBetween, children: [
                for (User user in snap.data!
                    .where((User u) =>
                        u.membership == Membership.join &&
                        u.id != sclient!.userID &&
                        u.id != sroom.user.id)
                    .take(9))
                  AccountCard(user: user),
              ]),
            ],
          );
        });
  }
}
