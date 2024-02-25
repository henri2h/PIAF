import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/chat/utils/matrix_widget.dart';
import 'package:piaf/chat/utils/spaces/space_extension.dart';

import '../components/buttons/custom_future_button.dart';

class FollowingIndicator extends StatelessWidget {
  const FollowingIndicator({super.key, required this.room, this.onUnfollow});

  final RoomWithSpace room;
  final VoidCallback? onUnfollow;

  Future<void> follow(Client client, BuildContext context) async {
    if (room.space == null) {
      final result = await showOkCancelAlertDialog(
          context: context,
          title: "Are you sure you want to unfollow this user?",
          message:
              "This action cannot be undone. If you were invited to this room you won't be able to join again without a new invitation.");
      if (result == OkCancelResult.ok) {
        await room.room?.leave();
        onUnfollow?.call();
      }
    }
    switch (room.space!.joinRule ?? '') {
      case "public":
        await client.joinRoom(room.space!
            .roomId); // TODO: update me to support joining over federation (need the via field)
        break;
      case "knock":
        await client.knockRoom(room.space!.roomId);
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    if (room.space == null && room.room == null) return Container();

    bool following = room.room != null;
    if (!following) {
      return CustomFutureButton(
          expanded: false,
          padding: const EdgeInsets.all(6),
          icon: Icon(following ? Icons.person : Icons.person_add),
          onPressed: () async => follow(Matrix.of(context).client, context),
          children: [Text(following ? "Following" : "Follow")]);
    }

    return PopupMenuButton(
        onSelected: (value) async {
          await follow(Matrix.of(context).client, context);
        },
        itemBuilder: (context) => [
              const PopupMenuItem(
                  value: "unfollow",
                  child: ListTile(
                      leading: Icon(
                        Icons.person_remove,
                        color: Colors.red,
                      ),
                      title: Text('Unfollow',
                          style: TextStyle(color: Colors.red)))),
            ],
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(following ? Icons.person : Icons.person_add),
              const SizedBox(
                width: 5,
              ),
              const Text("Following"),
            ],
          ),
        ));
  }
}
