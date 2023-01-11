import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/pages/minestrix/communities/community_page.dart';
import 'package:minestrix/partials/components/layouts/layout_view.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/view/room_settings_page.dart';

import '../../../partials/components/layouts/custom_header.dart';
import '../../../partials/minestrix_room_tile.dart';
import 'layout_main_feed.dart';

class CommunityDetailPage extends StatefulWidget {
  final Room room;

  const CommunityDetailPage({Key? key, required this.room}) : super(key: key);

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
          final children = CommunityPageState.getChildren(space).toList();
          final feedChildren = children.where((room) => room.isFeed);
          return LayoutView(
            controller: controller,
            displayChat: false,
            customHeader: CustomHeader(
              title: space
                  .getLocalizedDisplayname(const MatrixDefaultLocalizations()),
              actionButton: [
                IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      RoomSettingsPage.show(context: context, room: space);
                    })
              ],
            ),
            headerHeight: 300,
            room: space,
            headerChildBuilder: ({required bool displaySideBar}) => Container(),
            sidebarBuilder: ({required bool displayLeftBar}) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const H2Title("Groups"),
                  for (final room in feedChildren)
                    MinestrixRoomTileNavigator(room: room),
                ],
              ),
            ),
            mainBuilder: (
                    {required bool displaySideBar,
                    required bool displayLeftBar}) =>
                LayoutMainFeed(
              space: space,
              children: children,
              controller: feedController,
              displayPostModal: false,
            ),
          );
        });
  }
}
