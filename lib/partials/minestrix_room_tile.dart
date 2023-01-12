import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/minestrix/minestrix_room.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/partials/feed/minestrix_room_tile.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4),
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
        child: MinestrixRoomTile(room: room),
      ),
    );
  }
}
