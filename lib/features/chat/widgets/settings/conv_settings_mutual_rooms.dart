import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/utils/matrix/mutual_rooms_extension.dart';

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
      body: ListView(
        children: [
          MutualRoomsWidget(room: widget.room),
        ],
      ),
    );
  }
}

class MutualRoomsWidget extends StatelessWidget {
  const MutualRoomsWidget({
    super.key,
    required this.room,
  });

  final Room room;

  @override
  Widget build(BuildContext context) {
    final userId = room.directChatMatrixID;

    // We can't get the room in commons with ourselves
    if (userId == null || userId == room.client.userID) return Container();

    return FutureBuilder<List<String>?>(
        future: room.client.getMutualRoomsWithUser(userId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Column(
              children: [RoomListItemShimmer(), RoomListItemShimmer()],
            );
          }
          final list = snap.data!.where((element) => element != room.id);
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (list.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Mutual rooms",
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                for (final roomId in list)
                  Builder(builder: (context) {
                    final r = room.client.getRoomById(roomId);
                    if (r == null) return Container();
                    return RoomListItem(
                      key: Key("room_${r.id}"),
                      room: r,
                      opened: r == room,
                      onSelection: (_) {},
                      onLongPress: () {},
                    );
                  }),
              ]);
        });
  }
}
