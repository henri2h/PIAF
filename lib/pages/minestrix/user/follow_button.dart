import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/utils/spaces/space_extension.dart';

import '../../../partials/components/buttons/custom_future_button.dart';

class FollowingIndicator extends StatelessWidget {
  const FollowingIndicator({Key? key, required this.room, this.onUnfollow})
      : super(key: key);

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

    return CustomFutureButton(
        expanded: false,
        color: Theme.of(context).primaryColor,
        padding: const EdgeInsets.all(6),
        icon: Icon(following ? Icons.person : Icons.person_add,
            color: Theme.of(context).colorScheme.onPrimary),
        onPressed: () async => follow(Matrix.of(context).client, context),
        children: [
          Text(following ? "Following" : "Follow",
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary))
        ]);
  }
}
