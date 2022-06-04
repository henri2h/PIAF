import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/account/account_card.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/partials/users/user_room_knock_item.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/utils/room_feed_extension.dart';

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
    Client? sclient = Matrix.of(context).client;
    return FutureBuilder<List<User>>(
        future: getUsers(),
        initialData: room.getParticipants(),
        builder: (context, snap) {
          if (!snap.hasData) return CircularProgressIndicator();

          final usersSelection = snap.data!
              .where((User u) =>
                  u.membership == Membership.join &&
                  u.id != sclient.userID &&
                  u.id != room.userID)
              .take(12);

          snap.data!.forEach((element) {
            print("user ${element.displayName} ${element.membership}");
          });
          final knockingUsers =
              snap.data!.where((u) => u.membership == Membership.knock);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: MaterialButton(
                  onPressed: () {
                    if (room.isFeed) {
                      context.navigateTo(FriendsRoute());
                    } else {
                      context.navigateTo(UserFriendsRoute(room: room));
                    }
                  },
                  child: H2Title("Followers"),
                ),
              ),
              Wrap(alignment: WrapAlignment.spaceBetween, children: [
                for (User user in usersSelection) AccountCard(user: user),
              ]),
              if (room.canInvite && knockingUsers.isNotEmpty)
                H2Title("Follow request"),
              if (room.canInvite)
                for (User user in knockingUsers)
                  UserRoomKnockItem(user: user, room: room)
            ],
          );
        });
  }
}
