import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/partials/matrix/matrix_user_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

@RoutePage()
class RoomsExplorePage extends StatefulWidget {
  const RoomsExplorePage({super.key});

  @override
  State<RoomsExplorePage> createState() => _RoomsExplorePageState();
}

class _RoomsExplorePageState extends State<RoomsExplorePage> {
  final controller = ScrollController();

  String? nextBatch;
  final List<PublicRoomsChunk> rooms = [];

  Future<List> getPublicRooms(Client client) async {
    final response = await client.queryPublicRooms(
        since: nextBatch,
        limit: 20,
        filter: PublicRoomQueryFilter(roomTypes: [
          MatrixTypes.account,
          MatrixTypes.group,
          MatrixTypes.calendarEvent
        ]));

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
    return Scaffold(
        appBar: AppBar(title: const Text("Explore")),
        body: RefreshIndicator(
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
                        leading:
                            const Icon(Icons.not_listed_location, size: 40),
                        title: Text("No profile found",
                            style: Theme.of(context).textTheme.titleLarge),
                        subtitle: Text(
                          "All published profiles will be displayed here",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    for (final room in rooms)
                      ListTile(
                          leading: MatrixUserAvatar(
                            avatarUrl: room.avatarUrl,
                            userId: room.roomId,
                            name: room.name,
                            client: client,
                            height: MinestrixAvatarSizeConstants.avatar,
                            width: MinestrixAvatarSizeConstants.avatar,
                          ),
                          title: Text("${room.name}"),
                          subtitle: Text(room.roomType ?? ""),
                          trailing: Text("${room.numJoinedMembers}")),
                    if (futureRooms != null)
                      const Center(child: CircularProgressIndicator())
                  ],
                );
              }),
        ));
  }
}
