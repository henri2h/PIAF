import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/utils/profile_space.dart';
import 'package:minestrix_chat/utils/spaces/space_extension.dart';

class UserProfileSelection extends StatefulWidget {
  const UserProfileSelection(
      {Key? key,
      required this.userId,
      required this.onRoomSelected,
      required this.roomSelectedId})
      : super(key: key);
  final String userId;
  final String? roomSelectedId;
  final void Function(RoomWithSpace? r) onRoomSelected;

  @override
  _UserProfileSelectionState createState() => _UserProfileSelectionState();
}

class _UserProfileSelectionState extends State<UserProfileSelection> {
  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;

    final _rooms = client.sroomsByUserId[widget.userId]?.toList() ?? [];

    bool isOurProfile = widget.userId == client.userID;

    ProfileSpace? profile = ProfileSpace.getProfileSpace(client);

    return FutureBuilder<List<SpaceRoom>?>(
        future: ProfileSpace.getProfileSpaceHierarchy(client, widget.userId),
        builder: (context, snap) {
          final results = _rooms.map((e) => RoomWithSpace(room: e)).toList();
          final discoveredRooms = snap.data;

          discoveredRooms?.forEach((space) {
            final res =
                results.firstWhereOrNull((item) => item.room?.id == space.id);
            if (res != null) {
              res.space = space;
            } else {
              if (space.roomType == MatrixTypes.account) {
                results
                    .add(RoomWithSpace(space: space, creator: widget.userId));
              }
            }
          });

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MaterialButton(
                        padding: EdgeInsets.all(2),
                        disabledTextColor:
                            Theme.of(context).colorScheme.onBackground,
                        onPressed: isOurProfile
                            ? () => context.pushRoute(AccountsDetailsRoute())
                            : null,
                        child: H2Title("User profiles")),
                    if (profile == null && isOurProfile)
                      Card(
                        child: ListTile(
                            leading: Icon(Icons.create_new_folder),
                            title: Text("No user space found"),
                            subtitle: Text("Go to settings to create one"),
                            onTap: () =>
                                context.pushRoute(AccountsDetailsRoute())),
                      ),
                    if (results.isEmpty && !isOurProfile)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                              leading: Icon(Icons.question_mark),
                              title: Text("No profile found"),
                              subtitle: Text(
                                  "We weren't able to found a MinesTRIX profile related to this user. ")),
                        ),
                      ),
                    for (final r in results)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 2),
                        child: MaterialButton(
                            color: r.id == widget.roomSelectedId
                                ? Theme.of(context).primaryColor
                                : null,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  MatrixImageAvatar(
                                    client: client,
                                    url: r.avatar,
                                    thumnail: true,
                                    defaultText: r.displayname,
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    shape: MatrixImageAvatarShape.rounded,
                                    width: 45,
                                    height: 45,
                                  ),
                                  SizedBox(
                                    width: 8,
                                  ),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: 100),
                                    child: Text(r.displayname,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: r.id == widget.roomSelectedId
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                                : null,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                widget.onRoomSelected(r);
                              });
                            }),
                      ),
                  ],
                ),
              ),
            ],
          );
        });
  }
}

class RoomWithSpace {
  Room? room;
  SpaceRoom? space;

  /// Save the creator of the room in the case where we only have the space result
  String? _creator;

  String get id => room?.id ?? space!.id;
  String get displayname => room?.displayname ?? space?.name ?? '';
  String get topic => room?.topic ?? space?.topic ?? '';
  String? get creatorId => room?.creatorId ?? _creator;

  Uri? get avatar => room?.avatar;

  RoomWithSpace({this.room, this.space, String? creator}) {
    _creator = creator;
  }
}
