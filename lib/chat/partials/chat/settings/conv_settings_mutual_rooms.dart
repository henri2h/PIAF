import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/chat/utils/matrix/mutual_rooms_extension.dart';

import '../room_list/room_list_items/room_list_item.dart';

class ConvSettingsMutualRooms extends StatefulWidget {
  final Room room;
  const ConvSettingsMutualRooms({super.key, required this.room});

  @override
  State<ConvSettingsMutualRooms> createState() =>
      _ConvSettingsMutualRoomsState();
}

class _ConvSettingsMutualRoomsState extends State<ConvSettingsMutualRooms> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Mutual rooms"),
        forceMaterialTransparency: true,
      ),
      body: FutureBuilder<List<String>?>(
          future: widget.room.client
              .getMutualRoomsWithUser(widget.room.directChatMatrixID!),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Column(
                children: [
                  MatrixRoomsListTileShimmer(),
                  MatrixRoomsListTileShimmer()
                ],
              );
            }
            final list = snap.data!;
            return ListView(
              children: [
                for (final roomId in list)
                  Builder(builder: (context) {
                    final r = widget.room.client.getRoomById(roomId);
                    if (r == null) return Container();
                    return RoomListItem(
                      key: Key("room_${r.id}"),
                      room: r,
                      open: r == widget.room,
                      client: r.client,
                      onSelection: (_) {},
                      onLongPress: () {},
                    );
                  }),
              ],
            );
          }),
    );
  }
}
