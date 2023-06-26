import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/utils/matrix/mutual_rooms_extension.dart';
import '../room_list/room_list_items/room_list_item.dart';
import 'items/conv_setting_back_button.dart';

class ConvSettingsMutualRooms extends StatefulWidget {
  final Room room;
  const ConvSettingsMutualRooms({Key? key, required this.room})
      : super(key: key);

  @override
  State<ConvSettingsMutualRooms> createState() =>
      _ConvSettingsMutualRoomsState();
}

class _ConvSettingsMutualRoomsState extends State<ConvSettingsMutualRooms> {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Row(children: [
        ConvSettingsBackButton(),
        Text("Mutual rooms",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      Expanded(
        child: FutureBuilder<List<String>?>(
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
      ),
    ]);
  }
}
