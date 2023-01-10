import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/minestrix/minestrix_room.dart';
import 'package:minestrix_chat/partials/feed/minestrix_room_tile.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/utils/social/calendar_events/calendar_events_extension.dart';

import 'calendar_events/calendar_event_card.dart';

class ContactView extends StatelessWidget {
  const ContactView({
    Key? key,
    required this.sroom,
  }) : super(key: key);
  final MinestrixRoom sroom;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: TextButton(
          onPressed: () {
            context.navigateTo(UserViewRoute(userID: sroom.userID));
          },
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      MatrixImageAvatar(
                        client: Matrix.of(context).client,
                        url: sroom.avatar,
                        width: 32,
                        height: 32,
                        defaultIcon: const Icon(Icons.person, size: 32),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                    (sroom.user?.displayName ??
                                        sroom.userID ??
                                        'null'),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyText1!
                                            .color)),
                                Text(
                                  sroom.userID!,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyText1!
                                          .color),
                                )
                              ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
        ),
      ),
    );
  }
}

class MinestrixRoomTileNavigator extends StatelessWidget {
  const MinestrixRoomTileNavigator(
      {Key? key, required this.room, this.shouldPop = false})
      : super(key: key);
  final Room room;
  final bool shouldPop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: MaterialButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        onPressed: () async {
          if (shouldPop) Navigator.of(context).pop();
          if (room.feedType == FeedRoomType.group) {
            await context.navigateTo(GroupRoute(room: room));
          } else if (room.feedType == FeedRoomType.calendar) {
            await context.navigateTo(CalendarEventRoute(room: room));
          } else {
            context.navigateTo(UserViewRoute(mroom: room));
          }
        },
        child: room.feedType == FeedRoomType.calendar
            ? MinestrixCalendarRoomTile(room: room)
            : MinestrixRoomTile(room: room),
      ),
    );
  }
}

class MinestrixCalendarRoomTile extends StatelessWidget {
  const MinestrixCalendarRoomTile({Key? key, required this.room})
      : super(key: key);
  final Room room;

  @override
  Widget build(BuildContext context) {
    final calendarEvent = room.getEventAttendanceEvent();

    return SizedBox(
      height: 52,
      child: Row(
        children: [
          calendarEvent != null
              ? DateWidget(calendarEvent: calendarEvent)
              : MatrixImageAvatar(
                  client: room.client,
                  url: room.avatar,
                  defaultText: room.displayname,
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: MatrixImageAvatarShape.rounded,
                  width: 42,
                  height: 42,
                ),
          const SizedBox(
            width: 8,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(room.displayname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                if (room.topic != "")
                  Text(room.topic,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
