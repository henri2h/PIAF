import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/utils/matrix/mutual_rooms_extension.dart';
import '../room_list/matrix_rooms_list_tile.dart';
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
      Row(children: const [
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
                return Column(
                  children: const [
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
                      return MatrixRoomsListTile(
                          key: Key("room_${r.id}"),
                          room: r,
                          selected: r == widget.room,
                          client: r.client,
                          onSelection: (_) {});
                    }),
                ],
              );
            }),
      ),
    ]);
  }
}
