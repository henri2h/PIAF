import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/feed/minestrix_room_tile.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/utils/profile_space.dart';
import 'package:minestrix_chat/utils/spaces/space_extension.dart';

class UserProfileSelection extends StatefulWidget {
  const UserProfileSelection(
      {Key? key,
      required this.userId,
      required this.onRoomSelected,
      required this.roomSelectedId,
      this.dense = false})
      : super(key: key);
  final String userId;
  final bool dense;
  final String? roomSelectedId;
  final void Function(RoomWithSpace? r) onRoomSelected;

  @override
  UserProfileSelectionState createState() => UserProfileSelectionState();
}

class UserProfileSelectionState extends State<UserProfileSelection> {
  void selectRoom(RoomWithSpace? r) {
    setState(() {
      widget.onRoomSelected(r);
    });
  }

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;

    final rooms = client.sroomsByUserId[widget.userId]?.toList() ?? [];

    bool isOurProfile = widget.userId == client.userID;

    ProfileSpace? profile = ProfileSpace.getProfileSpace(client);

    return FutureBuilder<List<SpaceRoomsChunk>?>(
        future: ProfileSpace.getProfileSpaceHierarchy(client, widget.userId),
        builder: (context, snap) {
          final results = rooms.map((e) => RoomWithSpace(room: e)).toList();
          final discoveredRooms = snap.data;

          discoveredRooms?.forEach((space) {
            final res = results
                .firstWhereOrNull((item) => item.room?.id == space.roomId);
            if (res != null) {
              res.space = space;
            } else {
              if (space.roomType == MatrixTypes.account) {
                results
                    .add(RoomWithSpace(space: space, creator: widget.userId));
              }
            }
          });

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.dense)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      title: Text(isOurProfile ? "My profiles" : "Feeds"),
                      leading: const Icon(Icons.list),
                      onTap: isOurProfile
                          ? () =>
                              context.pushRoute(const AccountsDetailsRoute())
                          : null,
                    ),
                  ),
                if (profile == null && isOurProfile)
                  ListTile(
                      leading: const Icon(Icons.create_new_folder),
                      title: const Text("No user space found"),
                      subtitle: const Text("Go to settings to create one"),
                      onTap: () =>
                          context.pushRoute(const AccountsDetailsRoute())),
                if (results.isEmpty && !isOurProfile)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: ListTile(
                        leading: Icon(Icons.question_mark),
                        title: Text("No profile found"),
                        subtitle: Text(
                            "We weren't able to found a MinesTRIX profile related to this user. ")),
                  ),
                widget.dense
                    ? DropdownButton<RoomWithSpace>(
                        isExpanded: true,
                        value: results.firstWhereOrNull(
                            (element) => element.id == widget.roomSelectedId),
                        icon: const Icon(Icons.arrow_downward),
                        itemHeight: 52,
                        underline: Container(),
                        onChanged: (RoomWithSpace? c) {
                          selectRoom(c);
                        },
                        items: results.map<DropdownMenuItem<RoomWithSpace>>(
                            (RoomWithSpace room) {
                          return DropdownMenuItem<RoomWithSpace>(
                              value: room,
                              child: MinestrixRoomTile(
                                roomWithSpace: room,
                                client: client,
                                selected: room.id == widget.roomSelectedId,
                              ));
                        }).toList())
                    : Column(
                        children: [
                          for (final room in results)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 2, vertical: 2),
                              child: MaterialButton(
                                  color: room.id == widget.roomSelectedId
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: MinestrixRoomTile(
                                        roomWithSpace: room,
                                        client: client,
                                        selected:
                                            room.id == widget.roomSelectedId,
                                      )),
                                  onPressed: () => selectRoom(room)),
                            ),
                        ],
                      )
              ],
            ),
          );
        });
  }
}
