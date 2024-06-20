import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/matrix/matrix_image_avatar.dart';
import 'package:piaf/partials/matrix/matrix_user_avatar.dart';
import 'package:piaf/partials/utils/matrix_widget.dart';

class RoomListExplore extends StatefulWidget {
  const RoomListExplore({super.key, required this.onSelect});

  final void Function(String id) onSelect;

  @override
  State<RoomListExplore> createState() => _RoomListExploreState();
}

class _RoomListExploreState extends State<RoomListExplore> {
  final controller = ScrollController();

  String? nextBatch;
  final List<PublicRoomsChunk> rooms = [];

  Future<List> getPublicRooms(Client client) async {
    final response = await client.queryPublicRooms(
        since: nextBatch, filter: PublicRoomQueryFilter(roomTypes: []));
    rooms.addAll(response.chunk);

    nextBatch = response.nextBatch;
    futureRooms = null;
    return rooms;
  }

  Future<List>? futureRooms;

  late Client client;

  @override
  void initState() {
    client = Matrix.of(context).client;
    super.initState();
    futureRooms = getPublicRooms(client);
    controller.addListener(onScroll);
  }

  void onScroll() {
    if (controller.position.hasContentDimensions) {
      if (controller.position.extentAfter < 400) {
        if (futureRooms == null) {
          futureRooms ??= getPublicRooms(client);
          setState(() {});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        futureRooms = getPublicRooms(client);
        await futureRooms;
        setState(() {});
      },
      child: FutureBuilder<List>(
          future: futureRooms,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              controller: controller,
              children: [
                if (snapshot.hasData && rooms.isEmpty)
                  ListTile(
                    leading: const Icon(Icons.not_listed_location, size: 40),
                    title: Text("No profile found",
                        style: Theme.of(context).textTheme.titleLarge),
                    subtitle: Text(
                      "All published profiles will be displayed here",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                for (final room in rooms)
                  ListTile(
                      onTap: () {
                        widget.onSelect(room.roomId);
                      },
                      leading: MatrixUserAvatar(
                        avatarUrl: room.avatarUrl,
                        userId: room.roomId,
                        name: room.name,
                        client: client,
                        height: MinestrixAvatarSizeConstants.roomListAvatar,
                        width: MinestrixAvatarSizeConstants.roomListAvatar,
                      ),
                      title: Text("${room.name}"),
                      subtitle: Text(room.roomType ?? ""),
                      trailing: Text("${room.numJoinedMembers}")),
                if (futureRooms != null)
                  const Center(child: CircularProgressIndicator())
              ],
            );
          }),
    );
  }
}
