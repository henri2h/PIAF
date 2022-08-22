import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/account/account_card.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/partials/users/user_room_knock_item.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';

class UserFriendsCard extends StatelessWidget {
  const UserFriendsCard({Key? key, required this.room}) : super(key: key);

  final Room room;
  Future<List<User>> getUsers() async {
    return room.participantListComplete
        ? room.getParticipants()
        : await room.requestParticipants();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
        future: getUsers(),
        initialData: room.getParticipants(),
        builder: (context, snap) {
          if (!snap.hasData) return const CircularProgressIndicator();

          final usersSelection = snap.data!
              .where((User u) =>
                  u.membership == Membership.join && u.id != room.creatorId)
              .take(12);

          final knockingUsers =
              snap.data!.where((u) => u.membership == Membership.knock);

          return Column(
            children: [
              if (usersSelection.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                      onTap: room.creatorId != room.client.userID
                          ? null
                          : () {
                              context.pushRoute(FollowersRoute(room: room));
                            },
                      title: const Text("Followers"),
                      leading: const Icon(Icons.people)),
                ),
              Wrap(children: [
                for (User user in usersSelection) AccountCard(user: user),
              ]),
              if (room.canInvite && knockingUsers.isNotEmpty)
                const H2Title("Follow request"),
              if (room.canInvite)
                for (User user in knockingUsers)
                  UserRoomKnockItem(user: user, room: room)
            ],
          );
        });
  }
}
