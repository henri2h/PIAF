import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/layouts/layout_view.dart';
import 'package:piaf/partials/typo/titles.dart';
import 'package:piaf/partials/minestrix_chat.dart';
import 'package:piaf/features/chat/pages/room_settings_page.dart';
import '../../../partials/room_feed_tile_navigator.dart';
import '../../../utils/minestrix/minestrix_community_extension.dart';
import 'community_feed.dart';

@RoutePage()
class CommunityDetailPage extends StatefulWidget {
  final Room room;

  const CommunityDetailPage({super.key, required this.room});

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  final controller = ScrollController();
  final feedController = FeedController();

  @override
  void initState() {
    super.initState();

    controller.addListener(() {
      if (controller.position.maxScrollExtent - controller.position.pixels <
          800) {
        feedController.request();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final space = widget.room;

    return StreamBuilder(
        stream: space.onUpdate.stream,
        builder: (context, snapshot) {
          final children = Community.getChildren(space);
          final feedChildren = children.where((room) => room.isFeed);
          return LayoutView(
            controller: controller,
            displayChat: false,
            customHeaderText: space.getLocalizedDisplayname(),
            customHeaderActionsButtons: [
              IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    RoomSettingsPage.show(context: context, room: space);
                  })
            ],
            headerHeight: 300,
            room: space,
            sidebarBuilder: ({required bool displayLeftBar}) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const H2Title("Groups"),
                  for (final room in feedChildren)
                    RoomFeedTileNavigator(room: room),
                ],
              ),
            ),
            mainBuilder: (
                    {required bool displaySideBar,
                    required bool displayLeftBar}) =>
                CommunityFeed(
              key: Key("community_${space.id}"),
              space: space,
              children: children,
              controller: feedController,
              displayPostModal: false,
            ),
          );
        });
  }
}
