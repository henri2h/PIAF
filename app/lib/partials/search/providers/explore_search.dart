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
            if (room.guestCanJoin) const Badge(label: Text("Guests can join"))
          ],
        ),
        trailing: Text("${room.numJoinedMembers}"));
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
        filter: PublicRoomQueryFilter(roomTypes: [
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
  Future<void> setNewTerm(String text) {
    // TODO: implement setNewTerm
    throw UnimplementedError();
  }

  @override
  void init(BuildContext context) {
    client = Matrix.of(context).client;
  }
}
