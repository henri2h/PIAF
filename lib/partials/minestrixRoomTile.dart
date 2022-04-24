import 'package:flutter/material.dart';

import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';
import 'package:minestrix_chat/utils/room_feed_extension.dart';

import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrix_widget.dart';

import 'package:minestrix/utils/minestrix/minestrixRoom.dart';

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
                        defaultIcon: Icon(Icons.person, size: 32),
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

class MinestrixRoomTile extends StatelessWidget {
  const MinestrixRoomTile({
    Key? key,
    required this.room,
  }) : super(key: key);
  final Room room;

  @override
  Widget build(BuildContext context) {
    final Client? client = Matrix.of(context).client;

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: MaterialButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        onPressed: () async {
          if (room.type == FeedRoomType.group) {
            await context.navigateTo(GroupRoute(room: room));
          } else {
            context.navigateTo(UserViewRoute(userID: room.userID));
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      MatrixImageAvatar(
                        url: room.creator?.avatarUrl,
                        fit: true,
                        defaultText: room.name,
                        backgroundColor: Theme.of(context).primaryColor,
                        thumnail: true,
                        width: 46,
                        height: 46,
                        client: client,
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 2),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(room.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    )),
                                Text(
                                  room.topic,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(),
                                )
                              ]),
                        ),
                      ),
                    ],
                  ),
                ),
                if (room.encrypted)
                  Icon(Icons.verified_user,
                      color: Theme.of(context).textTheme.bodyText1!.color),
                if (!room.encrypted)
                  Icon(Icons.no_encryption,
                      color: Theme.of(context).textTheme.bodyText1!.color)
              ]),
        ),
      ),
    );
  }
}
