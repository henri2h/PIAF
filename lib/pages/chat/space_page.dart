import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/chat/room_list/room_list_items/room_list_item.dart';
import 'package:piaf/router.gr.dart';

import '../../partials/chat/spaces/space room_list_title.dart';
import '../../partials/style/constants.dart';
import '../../partials/dialogs/adaptative_dialogs.dart';
import '../../partials/matrix/matrix_image_avatar.dart';
import '../../partials/chat/room/room_participants_indicator.dart';
import '../../partials/chat/spaces/space_room_selection.dart';
import '../../partials/utils/matrix_widget.dart';

@RoutePage()
class SpacePage extends StatefulWidget {
  const SpacePage({super.key, required this.spaceId, this.onBack});

  final String spaceId;
  final void Function()? onBack;

  @override
  State<SpacePage> createState() => _SpacePageState();
}

class _SpacePageState extends State<SpacePage> {
  Future<List<SpaceRoomsChunk>>? rooms;
  Future<List<SpaceRoomsChunk>> loadRoomHierarchy() async {
    final client = Matrix.of(context).client;
    try {
      return (await client.getSpaceHierarchy(widget.spaceId)).rooms;
    } catch (e, s) {
      Logs().e("Could not get room hierarchy", e, s);
    }
    return [];
  }

  Future<void> addRoomToSpace() async {
    await AdaptativeDialogs.show(
        context: context,
        title: 'Select rooms',
        builder: (context) => SpaceRoomSelection());
  }

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    final room = client.getRoomById(widget.spaceId);

    return FutureBuilder(
        future: room?.postLoad(),
        builder: (context, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                "${room?.getLocalizedDisplayname()}",
              ),
            ),
            body: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Row(
                        children: [
                          if (room != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: MatrixImageAvatar(
                                  shape: MatrixImageAvatarShape.rounded,
                                  height: MinestrixAvatarSizeConstants.large,
                                  width: MinestrixAvatarSizeConstants.large,
                                  client: client,
                                  url: room.avatar,
                                  defaultText: room.getLocalizedDisplayname()),
                            ),
                          Expanded(
                              child: ListTile(
                                  title: Text(room?.getLocalizedDisplayname() ??
                                      widget.spaceId),
                                  subtitle: room?.topic != null
                                      ? Text(room!.topic)
                                      : null)),
                        ],
                      ),
                    ),
                  ),
                ),
                if (room != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ListTile(
                            leading: room.joinRules == JoinRules.public
                                ? const Icon(Icons.public)
                                : const Icon(Icons.lock),
                            title: Text(room.joinRules == JoinRules.public
                                ? "Public space"
                                : "Private space")),
                        ListTile(
                          leading: const Icon(Icons.people),
                          title: Text(
                              "${room.summary.mJoinedMemberCount} participants"),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: RoomParticipantsIndicator(room: room),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Rooms and spaces",
                          style: Constants.kTextTitleStyle),
                      MaterialButton(
                          onPressed: addRoomToSpace,
                          child: const Text("Add room")),
                    ],
                  ),
                ),
                FutureBuilder<List<SpaceRoomsChunk>>(
                    future: rooms ??= loadRoomHierarchy(),
                    builder: (context, snap) {
                      final rooms = snap.data;

                      return Column(
                        children: [
                          if (rooms == null)
                            const Column(
                              children: [
                                MatrixRoomsListTileShimmer(),
                                MatrixRoomsListTileShimmer(),
                                MatrixRoomsListTileShimmer(),
                              ],
                            ),
                          if (rooms != null)
                            ListView.builder(
                                shrinkWrap: true,
                                itemCount: rooms.length,
                                itemBuilder: (BuildContext context, int i) {
                                  final room = rooms[i];
                                  return SpaceRoomListTile(
                                      room: room,
                                      client: client,
                                      onPressed: () async {
                                        await context.pushRoute(
                                            RoomRoute(roomId: room.roomId));
                                      },
                                      onJoinPressed: () async {
                                        for (final r in rooms) {
                                          for (final rchild
                                              in r.childrenState) {
                                            if (rchild.stateKey ==
                                                room.roomId) {
                                              final via = rchild.content
                                                  .tryGetList<String>("via");
                                              await client.joinRoom(room.roomId,
                                                  serverName: via);
                                              setState(() {});
                                            }
                                          }
                                        }
                                      });
                                })
                        ],
                      );
                    })
              ],
            ),
          );
        });
  }
}
