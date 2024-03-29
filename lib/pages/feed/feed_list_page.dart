import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/components/layouts/custom_header.dart';
import 'package:piaf/router.gr.dart';
import 'package:piaf/utils/minestrix/minestrix_client_extension.dart';
import 'package:piaf/chat/minestrix_chat.dart';
import 'package:piaf/chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:piaf/chat/utils/matrix_widget.dart';

import '../../partials/room_feed_tile_navigator.dart';
import '../groups/create_group_page.dart';

@RoutePage()
class FeedListPage extends StatefulWidget {
  const FeedListPage({super.key});

  @override
  State<FeedListPage> createState() => _FeedListPageState();
}

enum Selection { all, feed, group, publicFeed }

class _FeedListPageState extends State<FeedListPage> {
  Set<String> selected = {"all"};
  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    return Column(
      children: [
        CustomHeader(
          title: "Feeds",
          actionButton: [FeedsAddMenuButton(client: client)],
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SegmentedButton<String>(
                onSelectionChanged: (value) {
                  setState(() {
                    selected = value;
                  });
                },
                segments: [
                  ButtonSegment(
                      value: Selection.all.name,
                      icon: const Icon(Icons.home),
                      label: const Text("All")),
                  ButtonSegment(
                      value: Selection.feed.name,
                      icon: const Icon(Icons.person),
                      label: const Text("People")),
                  ButtonSegment(
                      value: Selection.group.name,
                      icon: const Icon(Icons.people),
                      label: const Text("Group"))
                ],
                selected: selected),
          ),
        ),
        Expanded(
          child: StreamBuilder<Object>(
              stream: client.onSync.stream,
              builder: (context, snapshot) {
                return ListView(
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text("Suggestions"),
                              subtitle: const Text(
                                  "Follow suggestions based on your friends followers."),
                              trailing: const Icon(Icons.navigate_next),
                              onTap: () {
                                context.pushRoute(
                                    const FollowRecommendationsRoute());
                              },
                            ),
                            for (final room in client.rooms.where((element) {
                              if (element.isFeed) {
                                if (selected.first == Selection.feed.name) {
                                  return element.feedType == FeedRoomType.user;
                                } else if (selected.first ==
                                    Selection.group.name) {
                                  return element.feedType == FeedRoomType.group;
                                } else {
                                  return element.feedType ==
                                          FeedRoomType.user ||
                                      element.feedType == FeedRoomType.group;
                                }
                              }
                              return false;
                            }))
                              RoomFeedTileNavigator(room: room),
                          ],
                        ),
                      ),
                    )
                  ],
                );
              }),
        ),
      ],
    );
  }
}

class FeedsAddMenuButton extends StatelessWidget {
  const FeedsAddMenuButton({
    super.key,
    required this.client,
  });

  final Client client;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Selection>(
        icon: const Icon(Icons.add),
        onSelected: (Selection selection) async {
          switch (selection) {
            case Selection.feed:
              await client.createPrivateMinestrixProfile();
              break;
            case Selection.publicFeed:
              await client.createPublicMinestrixProfile();
              break;
            case Selection.all:
              break;
            case Selection.group:
              await AdaptativeDialogs.show(
                  context: context,
                  builder: (context) => const CreateGroupPage());
              break;
          }
        },
        itemBuilder: (context) => [
              const PopupMenuItem(
                  value: Selection.feed,
                  child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Create personal feed'))),
              const PopupMenuItem(
                  value: Selection.publicFeed,
                  child: ListTile(
                      leading: Icon(Icons.public),
                      title: Text('Create public feed'))),
              const PopupMenuItem(
                  value: Selection.group,
                  child: ListTile(
                      leading: Icon(Icons.people),
                      title: Text('Create group'))),
            ]);
  }
}
