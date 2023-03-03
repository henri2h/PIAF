import 'package:flutter/material.dart';
import 'package:minestrix/partials/components/layouts/custom_header.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../../partials/minestrix_room_tile.dart';
import 'groups/create_group_page.dart';

class FeedListPage extends StatefulWidget {
  const FeedListPage({Key? key}) : super(key: key);

  @override
  State<FeedListPage> createState() => _FeedListPageState();
}

enum Selection { all, feed, group, public_feed }

class _FeedListPageState extends State<FeedListPage> {
  Set<String> selected = {"all"};
  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    return Column(
      children: [
        CustomHeader(
          title: "Feeds",
          actionButton: [
            PopupMenuButton<Selection>(
                icon: const Icon(Icons.add),
                onSelected: (Selection selection) async {
                  switch (selection) {
                    case Selection.feed:
                      await client.createPrivateMinestrixProfile();
                      break;
                    case Selection.public_feed:
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
                          value: Selection.public_feed,
                          child: ListTile(
                              leading: Icon(Icons.public),
                              title: Text('Create public feed'))),
                      const PopupMenuItem(
                          value: Selection.group,
                          child: ListTile(
                              leading: Icon(Icons.people),
                              title: Text('Create group'))),
                    ])
          ],
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
                              MinestrixRoomTileNavigator(room: room),
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
