import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/router.gr.dart';
import 'package:piaf/config/matrix_types.dart';
import 'package:piaf/partials/chat_feed/posts/matrix_post_editor.dart';
import 'package:piaf/partials/matrix/matrix_user_avatar.dart';
import 'package:piaf/partials/minestrix_chat.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostHeader extends StatelessWidget {
  final Event event;
  final Event? eventToEdit;
  final bool allowContext; // allow context menu
  const PostHeader(
      {super.key,
      required this.event,
      this.eventToEdit,
      this.allowContext = true});

  @override
  Widget build(BuildContext context) {
    final Client sclient = event.room.client;
    Room? room = event.room;
    if (event.room.client.userID == null) {
      return const CircularProgressIndicator();
    }

    return FutureBuilder<User?>(
        future: event.fetchSenderUser(),
        builder: (context, snap) {
          final sender = snap.data ?? event.senderFromMemoryOrFallback;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: MatrixUserAvatar.fromUser(
                          sender,
                          client: sclient,
                        ),
                      ),
                      if (room.feedType == FeedRoomType.user)
                        Flexible(
                          child: Builder(builder: (BuildContext context) {
                            User? feedOwner = event.room.creator;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    TextButton(
                                      style: TextButton.styleFrom(
                                          foregroundColor: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .color),
                                      onPressed: () {
                                        context.navigateTo(UserViewRoute(
                                            userID: event.senderId));
                                      },
                                      child: Text(
                                          (sender.displayName ?? sender.id),
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    if (sender.id != feedOwner?.id)
                                      Text("to",
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .color)),
                                    if (sender.id != feedOwner?.id)
                                      TextButton(
                                        style: TextButton.styleFrom(
                                            foregroundColor: Theme.of(context)
                                                .textTheme
                                                .bodyLarge!
                                                .color),
                                        onPressed: () {
                                          context.navigateTo(
                                              UserViewRoute(mroom: event.room));
                                        },
                                        child: Text(
                                            (feedOwner?.displayName ??
                                                feedOwner?.id ??
                                                "null"),
                                            overflow: TextOverflow.clip,
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w400)),
                                      ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Row(
                                    children: [
                                      Text(timeago.format(event.originServerTs),
                                          style: TextStyle(
                                              fontWeight: FontWeight.normal,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall!
                                                  .color)),
                                      const SizedBox(width: 4),
                                      if (room.joinRules == JoinRules.public)
                                        Icon(Icons.public,
                                            size: 16,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall!
                                                .color),
                                      if (room.encrypted)
                                        Icon(Icons.lock,
                                            size: 16,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall!
                                                .color),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      if (room.feedType == FeedRoomType.group ||
                          room.feedType == FeedRoomType.calendar)
                        Flexible(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    context.navigateTo(
                                        UserViewRoute(userID: event.senderId));
                                  },
                                  child: Text((sender.displayName ?? sender.id),
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .color,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                ),
                                Text("to",
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .color)),
                                TextButton(
                                  onPressed: () async {
                                    if (room.feedType == FeedRoomType.group) {
                                      await context.navigateTo(
                                          GroupRoute(roomId: room.id));
                                    } else {
                                      await context.navigateTo(
                                          CalendarEventRoute(room: room));
                                    }
                                  },
                                  child: Text(event.room.name,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .color,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w400)),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(timeago.format(event.originServerTs),
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .color)),
                                const SizedBox(width: 4),
                                if (room.joinRules == JoinRules.public)
                                  Icon(Icons.public,
                                      size: 16,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .color),
                                if (room.encrypted)
                                  Icon(Icons.lock,
                                      size: 16,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .color),
                              ],
                            ),
                          ],
                        )),
                    ],
                  ),
                ),
              ),
              if (event.canRedact && allowContext)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      PopupMenuButton<String>(
                          itemBuilder: (_) => [
                                if (event.canRedact)
                                  const PopupMenuItem(
                                      value: "edit",
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 10),
                                          Text("Edit post"),
                                        ],
                                      )),
                                if (event.canRedact &&
                                    event.type == MatrixTypes.post)
                                  const PopupMenuItem(
                                      value: "delete",
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 10),
                                          Text("Delete post",
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ],
                                      ))
                              ],
                          icon: const Icon(Icons.more_horiz),
                          onSelected: (String action) async {
                            switch (action) {
                              case "delete":
                                try {
                                  if (event.status == EventStatus.sending) {
                                    await event.remove();
                                  } else {
                                    await event.redactEvent();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text("Could not delete post $e"),
                                    ));
                                  }
                                }
                                break;

                              case "edit":
                                await PostEditorPage.showEditModalAndEdit(
                                    context: context,
                                    eventToEdit: eventToEdit,
                                    event: event);
                                break;

                              default:
                                Logs().e("Unknow action $action");
                            }
                          })
                    ],
                  ),
                )
            ],
          );
        });
  }
}
