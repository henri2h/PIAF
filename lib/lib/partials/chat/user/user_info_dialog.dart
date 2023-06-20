import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/utils/matrix/mutual_rooms_extension.dart';
import 'package:minestrix_chat/utils/matrix/user_extension.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../dialogs/adaptative_dialogs.dart';
import '../../matrix/matrix_image_avatar.dart';
import '../room_list/room_list_items/room_list_item.dart';
import '../settings/room/room_encryption_settings.dart';

class UserInfoDialog extends StatelessWidget {
  static Future<void> show(
      {required User user, required BuildContext context}) async {
    await AdaptativeDialogs.show(
        context: context,
        bottomSheet: true,
        builder: (context) => UserInfoDialog(user: user));
  }

  final User user;
  const UserInfoDialog({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final client = user.room.client;
    return ListView(
      children: [
        SizedBox(
          height: 250,
          child: Stack(
            children: [
              MatrixImageAvatar(
                  client: user.room.client,
                  url: user.avatarUrl,
                  unconstraigned: true,
                  shape: MatrixImageAvatarShape.none,
                  defaultText: user.calcDisplayname(),
                  width: MinestrixAvatarSizeConstants.big,
                  height: MinestrixAvatarSizeConstants.big),
              Container(
                color: Colors.black45,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_downward),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      Text(user.calcDisplayname(),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          final roomId = await user.startDirectChat();
                          // TODO: navigate and display direct chat
                        },
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        PresenceIndicator(room: user.room, userID: user.id),
        if (user.displayName != null)
          ListTile(
              title: const Text("Matrix Id"),
              subtitle:
                  Text(user.id, style: Theme.of(context).textTheme.bodySmall)),
        ListTile(
            title: Text("Role in ${user.room.displayname}"),
            subtitle: Text(user.powerLevelText)),
        FutureBuilder<List<String>?>(
            future: user.room.client.getMutualRoomsWithUser(user.id),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snap.data!;
              return Column(
                children: [
                  for (final roomId in list)
                    Builder(builder: (context) {
                      final room = client.getRoomById(roomId);
                      if (room == null) return Container();
                      return RoomListItem(
                          key: Key("room_${room.id}"),
                          room: room,
                          selected: room == user.room,
                          client: room.client,
                          onSelection: (_) {});
                    }),
                ],
              );
            }),
        ExpansionTile(title: const Text("User Keys"), children: [
          RoomUserDeviceKey(
            room: user.room,
            userId: user.senderId,
          ),
        ]),
      ],
    );
  }
}

class PresenceIndicator extends StatelessWidget {
  const PresenceIndicator({Key? key, required this.room, required this.userID})
      : super(key: key);

  final Room room;
  final String userID;
  @override
  Widget build(BuildContext context) {
    final presence = room.client.presences[userID];
    if (presence == null) return Container();
    return ListTile(
      title: const Text("Last seen"),
      subtitle: Text(presence.currentlyActive == true
          ? "Currently active"
          : presence.lastActiveTimestamp != null
              ? timeago.format(presence.lastActiveTimestamp!)
              : "a long time ago"),
    );
  }
}
