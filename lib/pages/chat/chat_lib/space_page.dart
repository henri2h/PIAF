import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/chat/room_list/room_list_items/room_list_item.dart';

import '../../../partials/style/constants.dart';
import '../../../partials/dialogs/adaptative_dialogs.dart';
import '../../../partials/matrix/matrix_image_avatar.dart';
import '../../../partials/chat/room/room_participants_indicator.dart';
import '../../../partials/chat/spaces/space_room_selection.dart';

@RoutePage()
class SpacePage extends StatefulWidget {
  const SpacePage(
      {super.key, required this.spaceId, required this.client, this.onBack});

  final String spaceId;
  final Client client;
  final void Function()? onBack;

  @override
  State<SpacePage> createState() => _SpacePageState();
}

class _SpacePageState extends State<SpacePage> {
  Future<List<SpaceRoomsChunk>>? rooms;
  Future<List<SpaceRoomsChunk>> loadRoomHierarchy() async {
    try {
      return (await widget.client.getSpaceHierarchy(widget.spaceId)).rooms;
    } catch (e, s) {
      Logs().e("Could not get room hierarchy", e, s);
    }
    return [];
  }

  Future<void> addRoomToSpace() async {
    await AdaptativeDialogs.show(
        context: context,
        title: 'Select rooms',
        builder: (context) => SpaceRoomSelection(
              client: widget.client,
            ));
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.client.getRoomById(widget.spaceId);

    return FutureBuilder(
        future: room?.postLoad(),
        builder: (context, _) {
          return FutureBuilder<List<SpaceRoomsChunk>>(
              future: rooms ??= loadRoomHierarchy(),
              builder: (context, snap) {
                final rooms = snap.data;

                return Scaffold(
                  appBar: AppBar(
                    title: Text(
                      "${room?.getLocalizedDisplayname()}",
                    ),
                  ),
                  body: ListView(
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Row(
                            children: [
                              if (room != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: MatrixImageAvatar(
                                      shape: MatrixImageAvatarShape.rounded,
                                      height:
                                          MinestrixAvatarSizeConstants.large,
                                      width: MinestrixAvatarSizeConstants.large,
                                      client: widget.client,
                                      url: room.avatar,
                                      defaultText:
                                          room.getLocalizedDisplayname()),
                                ),
                              Expanded(
                                  child: ListTile(
                                      title: Text(
                                          room?.displayname ?? widget.spaceId),
                                      subtitle: room?.topic != null
                                          ? Text(room!.topic)
                                          : null)),
                            ],
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
                                      child:
                                          RoomParticipantsIndicator(room: room),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Rooms and spaces",
                              style: Constants.kTextTitleStyle),
                          MaterialButton(
                              onPressed: addRoomToSpace,
                              child: const Text("Add room")),
                        ],
                      ),
                      if (rooms == null)
                        const Column(
                          children: [
                            MatrixRoomsListTileShimmer(),
                            MatrixRoomsListTileShimmer(),
                            MatrixRoomsListTileShimmer(),
                          ],
                        ),
                      if (rooms != null)
                        for (final room in rooms)
                          ListTile(
                            leading: MatrixImageAvatar(
                                shape: room.roomType == "m.space"
                                    ? MatrixImageAvatarShape.rounded
                                    : MatrixImageAvatarShape.circle,
                                client: widget.client,
                                url: room.avatarUrl,
                                defaultText: room.name),
                            title: Text(room.name ?? ''),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (room.topic != null)
                                  Text(
                                    room.topic!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                Row(
                                  children: [
                                    const Icon(Icons.people),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4.0),
                                      child: Text(
                                          "${room.numJoinedMembers} participants"),
                                    )
                                  ],
                                )
                              ],
                            ),
                            trailing: widget.client.getRoomById(room.roomId) ==
                                    null
                                ? MaterialButton(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    onPressed: () async {
                                      for (final r in rooms) {
                                        for (final rchild in r.childrenState) {
                                          if (rchild.stateKey == room.roomId) {
                                            final via = rchild.content
                                                .tryGetList<String>("via");
                                            await widget.client.joinRoom(
                                                room.roomId,
                                                serverName: via);
                                            setState(() {});
                                          }
                                        }
                                      }
                                    },
                                    child: const Text("join"))
                                : null,
                          )
                    ],
                  ),
                );
              });
        });
  }
}
