import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/minestrix/minestrix_title.dart';
import 'package:minestrix/utils/minestrix/minestrix_community_extension.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../../../partials/calendar_events/calendar_event_create_widget.dart';
import '../../../partials/minestrix_room_tile.dart';
import '../../../partials/navigation/rightbar.dart';
import '../../../router.gr.dart';

@RoutePage()
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => CommunityPageState();
}

class CommunityPageState extends State<CommunityPage> {
  Future<void> onCommunityPressed(Room room) async {
    await context.navigateTo(CommunityDetailRoute(room: room));
  }

  Future<void> createCommunity() async {
    await CalendarEventCreateWidget.show(context);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Communities"),
        actions: [
          FilledButton.icon(
              onPressed: createCommunity,
              icon: const Icon(Icons.add),
              label: const Text("Add")),
        ],
      ),
      body: StreamBuilder(
          stream: client.onSync.stream.where((sync) => sync.hasRoomUpdate),
          builder: (context, snapshot) {
            final communities = client.getCommunities();
            return LayoutBuilder(builder: (context, constraints) {
              final feedOnly = constraints.maxWidth < 860;
              return Row(
                children: [
                  Expanded(
                    child: ListView.builder(
                        itemCount: communities.length,
                        itemBuilder: (context, pos) {
                          final community = communities[pos];
                          final space = community.space;

                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: MaterialButton(
                                onPressed: () async =>
                                    await onCommunityPressed(space),
                                child: Card(
                                    child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Wrap(
                                    children: [
                                      SizedBox(
                                        width: 300,
                                        child: FutureBuilder(
                                            future: space.postLoad(),
                                            builder: (context, snapshot) {
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  H2Title(space
                                                      .getLocalizedDisplayname(
                                                          const MatrixDefaultLocalizations())),
                                                  Text(space.topic),
                                                  MatrixImageAvatar(
                                                    client: client,
                                                    url: space.avatar,
                                                    defaultText:
                                                        space.displayname,
                                                    shape:
                                                        MatrixImageAvatarShape
                                                            .rounded,
                                                    width: 200,
                                                    height: 200,
                                                  ),
                                                  ListTile(
                                                    leading: const Icon(
                                                        Icons.people),
                                                    title:
                                                        const Text("Members"),
                                                    trailing: Text(
                                                        space.summary
                                                            .mJoinedMemberCount
                                                            .toString(),
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  )
                                                ],
                                              );
                                            }),
                                      ),
                                      ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 500),
                                        child: Column(
                                          children: [
                                            for (final room
                                                in community.children)
                                              MinestrixRoomTileNavigator(
                                                  room: room),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                )),
                              ),
                            ),
                          );
                        }),
                  ),
                  if (!feedOnly)
                    ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: const RightBar()),
                ],
              );
            });
          }),
    );
  }
}
