import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/chat/minestrix_chat.dart';
import 'package:minestrix/chat/partials/feed/minestrix_room_tile.dart';

class MinestrixRoomTileNavigator extends StatelessWidget {
  const MinestrixRoomTileNavigator(
      {super.key, required this.room, this.shouldPop = false});
  final Room room;
  final bool shouldPop;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      padding: EdgeInsets.zero,
      onPressed: () async {
        if (shouldPop) Navigator.of(context).pop();
        if (room.isSpace) {
          await context.navigateTo(
              TabCommunityRoute(children: [CommunityDetailRoute(room: room)]));
        } else if (room.feedType == FeedRoomType.group) {
          await context.navigateTo(GroupRoute(roomId: room.id));
        } else if (room.feedType == FeedRoomType.calendar) {
          await context.navigateTo(CalendarEventRoute(room: room));
        } else {
          context.navigateTo(UserViewRoute(mroom: room));
        }
      },
      child: MinestrixRoomTile(room: room),
    );
  }
}
