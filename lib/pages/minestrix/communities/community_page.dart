import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../../../partials/components/layouts/custom_header.dart';
import '../../../partials/minestrix_room_tile.dart';
import '../../../router.gr.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({Key? key}) : super(key: key);

  @override
  State<CommunityPage> createState() => CommunityPageState();
}

class CommunityPageState extends State<CommunityPage> {
  static List<Room> getChildren(Room space) {
    List<Room> spaceChilds = [];

    for (var child in space.spaceChildren) {
      if (child.roomId != null && (child.via?.isNotEmpty ?? false)) {
        final room = space.client.getRoomById(child.roomId!);

        if (room?.isSpace == false) {
          spaceChilds.add(room!);
        }
      }
    }

    return spaceChilds;
  }

  Future<void> onCommunityPressed(Room room) async {
    await context.navigateTo(CommunityDetailRoute(room: room));
  }

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;

    return StreamBuilder(
        stream: client.onSync.stream.where((sync) => sync.hasRoomUpdate),
        builder: (context, snapshot) {
          final spaces = client.spaces.toList();
          return Column(
            children: [
              const CustomHeader(title: "Communities"),
              Expanded(
                  child: ListView.builder(
                      itemCount: spaces.length,
                      itemBuilder: (context, pos) {
                        final space = spaces[pos];
                        final children = getChildren(space)
                            .where((Room room) => room.isFeed);

                        if (children.isEmpty) return Container();

                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: MaterialButton(
                            onPressed: () async =>
                                await onCommunityPressed(space),
                            child: Card(
                                child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 400,
                                    child: FutureBuilder(
                                        future: space.postLoad(),
                                        builder: (context, snapshot) {
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              H2Title(space.getLocalizedDisplayname(
                                                  const MatrixDefaultLocalizations())),
                                              Text(space.topic),
                                              MatrixImageAvatar(
                                                client: client,
                                                url: space.avatar,
                                                defaultText: space.displayname,
                                                shape: MatrixImageAvatarShape
                                                    .rounded,
                                                width: 200,
                                                height: 200,
                                              ),
                                              ListTile(
                                                leading:
                                                    const Icon(Icons.people),
                                                title: const Text("Members"),
                                                trailing: Text(
                                                    space.summary
                                                        .mJoinedMemberCount
                                                        .toString(),
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              )
                                            ],
                                          );
                                        }),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        for (final room in children)
                                          MinestrixRoomTileNavigator(
                                              room: room),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            )),
                          ),
                        );
                      })),
            ],
          );
        });
  }
}
