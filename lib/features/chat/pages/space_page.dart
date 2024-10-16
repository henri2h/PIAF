import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/features/chat/widgets/room_list/room_list_items/room_list_item.dart';
import 'package:piaf/router.gr.dart';

import '../widgets/spaces/space room_list_title.dart';
import '../../../partials/style/constants.dart';
import '../../../partials/dialogs/adaptative_dialogs.dart';
import '../../../partials/matrix/matrix_image_avatar.dart';
import '../widgets/room/room_participants_indicator.dart';
import '../widgets/spaces/space_room_selection.dart';
import '../../../utils/matrix_widget.dart';

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
    final space = client.getRoomById(widget.spaceId);

    final children = space?.spaceChildren ?? [];

    return FutureBuilder(
        future: space?.postLoad(),
        builder: (context, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                "${space?.getLocalizedDisplayname()}",
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
                          if (space != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: MatrixImageAvatar(
                                  shape: MatrixImageAvatarShape.rounded,
                                  height: MinestrixAvatarSizeConstants.large,
                                  width: MinestrixAvatarSizeConstants.large,
                                  client: client,
                                  url: space.avatar,
                                  defaultText: space.getLocalizedDisplayname()),
                            ),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                  title: Text(
                                      space?.getLocalizedDisplayname() ??
                                          widget.spaceId),
                                  subtitle: space?.topic.isNotEmpty == true
                                      ? Text(space!.topic)
                                      : null),
                              if (space?.membership == Membership.invite)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: FilledButton(
                                      onPressed: () async {
                                        await space?.join();
                                        if (mounted) {
                                          setState(() {});
                                        }
                                      },
                                      child: Text("Join")),
                                ),
                            ],
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
                if (space != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ListTile(
                            leading: space.joinRules == JoinRules.public
                                ? const Icon(Icons.public)
                                : const Icon(Icons.lock),
                            title: Text(space.joinRules == JoinRules.public
                                ? "Public space"
                                : "Private space")),
                        ListTile(
                          leading: const Icon(Icons.people),
                          title: Text(
                              "${space.summary.mJoinedMemberCount} participants"),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: RoomParticipantsIndicator(room: space),
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
                ListView.builder(
                    shrinkWrap: true,
                    itemCount: children.length,
                    itemBuilder: (BuildContext context, int i) {
                      final spaceChild = children[i];
                      if (spaceChild.roomId != null) {
                        final room = client.getRoomById(spaceChild.roomId!);
                        if (room != null) {
                          return RoomListItem(room: room);
                        }
                      }
                      return null;
                    }),
                Divider(),
                FutureBuilder<List<SpaceRoomsChunk>>(
                    future: rooms ??= loadRoomHierarchy(),
                    builder: (context, snap) {
                      final spaceChunks = snap.data;

                      return Column(
                        children: [
                          if (spaceChunks == null)
                            const Column(
                              children: [
                                RoomListItemShimmer(),
                                RoomListItemShimmer(),
                                RoomListItemShimmer(),
                              ],
                            ),
                          if (spaceChunks != null)
                            ListView.builder(
                                shrinkWrap: true,
                                itemCount: spaceChunks.length,
                                physics: NeverScrollableScrollPhysics(),
                                itemBuilder: (BuildContext context, int i) {
                                  final spaceChunk = spaceChunks[i];
                                  if (spaceChunk.roomId == space?.id) {
                                    return null;
                                  }

                                  final room =
                                      client.getRoomById(spaceChunk.roomId);
                                  if (room != null) {
                                    // Check if this space has already beeen displayed previoulsly in the listView of the room.spaceChildren
                                    final wasAlreadyDisplayed =
                                        children.firstWhereOrNull((s) =>
                                                s.roomId ==
                                                spaceChunk.roomId) !=
                                            null;
                                    if (wasAlreadyDisplayed) {
                                      return null;
                                    }
                                    return RoomListItem(room: room);
                                  }

                                  return SpaceRoomListTile(
                                      room: spaceChunk,
                                      client: client,
                                      onPressed: () async {
                                        await context.pushRoute(RoomRoute(
                                            roomId: spaceChunk.roomId));
                                      },
                                      onJoinPressed: () async {
                                        for (final r in spaceChunks) {
                                          for (final rchild
                                              in r.childrenState) {
                                            if (rchild.stateKey ==
                                                spaceChunk.roomId) {
                                              final via = rchild.content
                                                  .tryGetList<String>("via");
                                              await client.joinRoom(
                                                  spaceChunk.roomId,
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
