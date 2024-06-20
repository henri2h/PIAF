import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:piaf/partials/minestrix_chat.dart';
import 'package:piaf/partials/utils/matrix_widget.dart';
import 'package:piaf/router.gr.dart';

import '../../partials/room_feed_tile_navigator.dart';

@RoutePage()
class FeedListPage extends StatefulWidget {
  const FeedListPage({super.key, required this.initialSelection});

  final Selection initialSelection;

  @override
  State<FeedListPage> createState() => _FeedListPageState();
}

enum Selection { all, feed, group, publicFeed }

class _FeedListPageState extends State<FeedListPage> {
  Set<Selection> selected = {};

  @override
  void initState() {
    super.initState();
    selected.add(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Feeds"),
        actions: [
          IconButton(
              onPressed: () async {
                await context.pushRoute(const FollowRecommendationsRoute());
              },
              icon: const Icon(Icons.person_search))
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await context.pushRoute(const FeedCreationRoute());
          },
          child: const Icon(Icons.add)),
      body: StreamBuilder<Object>(
          stream: client.onSync.stream,
          builder: (context, snapshot) {
            return ListView(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      children: [
                        for (final room in client.rooms.where((element) {
                          if (element.isFeed) {
                            if (selected.first == Selection.feed) {
                              return element.feedType == FeedRoomType.user;
                            } else if (selected.first == Selection.group) {
                              return element.feedType == FeedRoomType.group;
                            } else {
                              return element.feedType == FeedRoomType.user ||
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
    );
  }
}
