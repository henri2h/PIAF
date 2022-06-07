import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/utils/spaces/space_extension.dart';

import '../../../partials/components/buttons/customFutureButton.dart';

class FollowingIndicator extends StatelessWidget {
  const FollowingIndicator({Key? key, required this.room}) : super(key: key);

  final RoomWithSpace room;

  Future<void> follow(Client client) async {
    if (room.space == null) return;
    switch (room.space!.joinRule) {
      case JoinRules.public:
        await client.joinRoom(room.space!
            .id); // TODO: update me to support joining over federation (need the via field)
        break;
      case JoinRules.knock:
        await client.knockRoom(room.space!.id);
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
        padding: EdgeInsets.all(6),
        icon: Icon(following ? Icons.person : Icons.person_add,
            color: Theme.of(context).colorScheme.onPrimary),
        onPressed: () async => follow(Matrix.of(context).client),
        children: [
          Text(following ? "Following" : "Follow",
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary))
        ]);
  }
}
