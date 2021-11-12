import 'package:matrix/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:minestrix/global/helpers/NavigationHelper.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrix/SMatrixRoom.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostHeader extends StatelessWidget {
  final Event event;
  const PostHeader({Key key, this.event}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final SClient sclient = Matrix.of(context).sclient;
    SMatrixRoom sroom = sclient.srooms[event.roomId];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: MatrixUserImage(
                    client: sclient,
                    url: event.sender.avatarUrl,
                    width: 48,
                    height: 48,
                    thumnail: true,
                    defaultIcon: Icon(Icons.person, size: 48)),
              ),
              SizedBox(width: 10),
              if (sroom.roomType == SRoomType.UserRoom)
                Flexible(
                  child: FutureBuilder<Profile>(
                      future: sclient.getUserFromRoom(event.room),
                      builder:
                          (BuildContext context, AsyncSnapshot<Profile> p) {
                        if (p.hasData) {
                          User u = User(
                            p.data.userId,
                            displayName: p.data.displayName,
                            avatarUrl: p.data.avatarUrl.toString(),
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                        primary: Theme.of(context)
                                            .textTheme
                                            .bodyText1
                                            .color),
                                    onPressed: () {
                                      NavigationHelper.navigateToUserFeed(
                                          context, event.sender);
                                    },
                                    child: Text(event.sender.displayName,
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  if (event.sender.id != p.data.userId)
                                    Text("to",
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyText1
                                                .color)),
                                  if (event.sender.id != p.data.userId)
                                    TextButton(
                                      style: TextButton.styleFrom(
                                          primary: Theme.of(context)
                                              .textTheme
                                              .bodyText1
                                              .color),
                                      onPressed: () {
                                        NavigationHelper.navigateToUserFeed(
                                            context, u);
                                      },
                                      child: Text(p.data.displayName,
                                          overflow: TextOverflow.clip,
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400)),
                                    ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                    timeago.format(event.originServerTs),
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Theme.of(context)
                                            .textTheme
                                            .caption
                                            .color)),
                              ),
                            ],
                          );
                        }
                        return Text(event.sender.displayName,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold));
                      }),
                ),
              if (sroom.roomType == SRoomType.Group)
                Flexible(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: TextButton(
                            onPressed: () {
                              NavigationHelper.navigateToUserFeed(
                                  context, event.sender);
                            },
                            child: Text(event.sender.displayName,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyText1
                                        .color,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Text("to",
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyText1
                                    .color)),
                        Flexible(
                          child: TextButton(
                            onPressed: () {
                              NavigationHelper.navigateToGroup(
                                  context, event.roomId);
                            },
                            child: Text(sroom.name,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyText1
                                        .color,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400)),
                          ),
                        ),
                      ],
                    ),
                    Text(timeago.format(event.originServerTs),
                        style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: Theme.of(context).textTheme.caption.color)),
                  ],
                )),
            ],
          ),
        ),
        if (event.canRedact)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                /*  if (encyrpted)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.enhanced_encryption),
                ),*/
                PopupMenuButton<String>(
                    itemBuilder: (_) => [
                          if (event.canRedact)
                            PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 10),
                                    Text("Edit post"),
                                  ],
                                ),
                                value: "edit"),
                          if (event.canRedact)
                            PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 10),
                                    Text("Delete post",
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                                value: "delete")
                        ],
                    icon: Icon(Icons.more_horiz),
                    onSelected: (String action) async {
                      switch (action) {
                        case "delete":
                          await event.redactEvent();
                          break;
                        default:
                      }
                    })
              ],
            ),
          )
      ],
    );
  }
}
