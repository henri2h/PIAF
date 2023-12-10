import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/search/providers/lib.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/partials/matrix/matrix_user_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

class ExploreSearch implements ItemManager<PublicRoomsChunk> {
  String? nextBatch;
  late Client client;

  String? searchText;

  @override
  Widget itemBuilder(BuildContext context, PublicRoomsChunk room) {
    return ListTile(
        leading: MatrixUserAvatar(
          avatarUrl: room.avatarUrl,
          userId: room.roomId,
          name: room.name,
          client: client,
          height: MinestrixAvatarSizeConstants.avatar,
          width: MinestrixAvatarSizeConstants.avatar,
        ),
        title: Text("${room.name}"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (room.roomType?.isNotEmpty == true) Text(room.roomType!),
            Row(
              children: [
                Badge(label: Text("${room.numJoinedMembers} members")),
                const SizedBox(
                  width: 8,
                ),
                if (room.guestCanJoin)
                  const Badge(label: Text("Guests can join")),
              ],
            )
          ],
        ),
        trailing: client.getRoomById(room.roomId) != null
            ? const Text("Joined")
            : OutlinedButton(
                onPressed: () async {
                  try {
                    await client.joinRoomById(room.roomId);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  }
                },
                child: const Text("Join")));
  }

  @override
  Future<bool> requestMore() async {
    await getPublicRooms(client);
    return true;
  }

  Future<List> getPublicRooms(Client client) async {
    print("Getting public rooms");
    final response = await client.queryPublicRooms(
        since: nextBatch,
        filter: PublicRoomQueryFilter(
            genericSearchTerm: searchText,
            roomTypes: [
              MatrixTypes.account,
              MatrixTypes.group,
              MatrixTypes.calendarEvent
            ]));

    items.addAll(response.chunk);

    nextBatch = response.nextBatch;

    return items;
  }

  @override
  List<PublicRoomsChunk> items = [];

  @override
  Future<void> setNewTerm(String text) async {
    searchText = text;
    nextBatch = null;
    items.clear();

    await requestMore();
  }

  @override
  void init(BuildContext context) {
    client = Matrix.of(context).client;
  }
}
