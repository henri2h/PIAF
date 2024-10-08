
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../../matrix/matrix_image_avatar.dart';

class SpaceRoomListTile extends StatelessWidget {
  const SpaceRoomListTile(
      {super.key,
      required this.room,
      required this.client,
      required this.onPressed,
      required this.onJoinPressed});
  final SpaceRoomsChunk room;
  final Client client;

  final VoidCallback onPressed;
  final VoidCallback onJoinPressed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onPressed,
      leading: MatrixImageAvatar(
          shape: room.roomType == "m.space"
              ? MatrixImageAvatarShape.rounded
              : MatrixImageAvatarShape.circle,
          client: client,
          url: room.avatarUrl,
          defaultText: room.name),
      title: Text(room.name ?? ''),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (room.topic != null)
            Text(
              room.topic!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          Row(
            children: [
              const Icon(Icons.people),
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text("${room.numJoinedMembers} participants"),
              )
            ],
          )
        ],
      ),
      trailing: client.getRoomById(room.roomId) == null
          ? MaterialButton(
              color: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              onPressed: onPressed,
              child: const Text("join"))
          : null,
    );
  }
}
