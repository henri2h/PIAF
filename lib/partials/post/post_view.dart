import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/partials/matrix/reactions_list.dart';
import 'package:minestrix_chat/utils/events/event_extension.dart';

import 'details/post_content.dart';
import 'details/post_header.dart';
import 'details/post_reactions.dart';
import 'details/post_replies.dart';
import 'post.dart';

class PostView extends StatelessWidget {
  final PostState controller;
  const PostView({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Timeline?>(
        future: controller.futureTimeline,
        builder: (context, snap) {
          Timeline? t = snap.data;

          final displayEvent = t != null
              ? controller.post.event!
                  .getDisplayEventWithType(t, MatrixTypes.post)
              : controller.post.event!;

          return Card(
            key: key,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // post content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PostHeader(
                        eventToEdit: controller.post.event!,
                        event: displayEvent),
                    if (controller.post.event!.status != EventStatus.synced)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child:
                            Text("Not sent ${controller.post.event!.status}"),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: PostContent(
                        displayEvent,
                        imageMaxHeight: 300,
                      ),
                    ),
                    if (controller.shareEvent != null)
                      FutureBuilder<Event?>(
                          future: controller.shareEvent,
                          builder: (context, snap) {
                            if (snap.hasError)
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.error),
                                    SizedBox(width: 4),
                                    Text(snap.error.toString()),
                                  ],
                                ),
                              );
                            if (!snap.hasData)
                              return CircularProgressIndicator();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text("Sharing"),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Container(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        PostHeader(
                                            event: snap.data!,
                                            allowContext: false),
                                        PostContent(
                                          snap.data!,
                                          imageMaxHeight: 300,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                if (controller.reactions?.isNotEmpty ?? false)
                                  Flexible(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: MaterialButton(
                                                child: PostReactions(
                                                    event:
                                                        controller.post.event!,
                                                    reactions:
                                                        controller.reactions!),
                                                onPressed: () async {
                                                  await AdaptativeDialogs.show(
                                                      context: context,
                                                      builder: (context) =>
                                                          EventReactionList(
                                                              reactions: controller
                                                                  .reactions!),
                                                      title: "Reactions");
                                                }),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (controller.replies?.isNotEmpty ?? false)
                                  MaterialButton(
                                      child: Text((controller.showReplies
                                              ? "Hide "
                                              : "Show ") +
                                          controller.replies!.length
                                              .toString() +
                                          " comments"),
                                      onPressed: controller.toggleReplyView),
                              ],
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            child: MaterialButton(
                                elevation: 0,
                                color: Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.insert_emoticon_rounded,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary),
                                    SizedBox(width: 5),
                                    Text("Reaction",
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary))
                                  ],
                                ),
                                onPressed: () {}),
                            onTapDown: (TapDownDetails detail) async {
                              controller.onReact(detail.globalPosition);
                            },
                          ),
                          SizedBox(width: 9),
                          MaterialButton(
                            elevation: 0,
                            color: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.reply,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary),
                                SizedBox(width: 5),
                                Text("Comment",
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary))
                              ],
                            ),
                            onPressed: controller.replyButtonClick,
                          ),
                          if (displayEvent.room.historyVisibility ==
                                  HistoryVisibility.worldReadable &&
                              displayEvent
                                  .room.client.minestrixUserRoom.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 9.0),
                              child: MaterialButton(
                                elevation: 0,
                                color: Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.share,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary),
                                    SizedBox(width: 5),
                                    Text("Share",
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary))
                                  ],
                                ),
                                onPressed: controller.share,
                              ),
                            ),
                        ],
                      ),
                    )
                  ],
                ),
                (controller.replyToMessageId != null ||
                            controller.showReplies) &&
                        t != null
                    ? Container(
                        child: Column(
                          children: [
                            Divider(),
                            if (controller.replyToMessageId != null ||
                                controller.showReplies)
                              RepliesVue(
                                  timeline: t,
                                  event: controller.post.event!,
                                  postEvent: controller.post.event!,
                                  replies: (controller.showReplies &&
                                          controller.replies?.isNotEmpty ==
                                              true)
                                      ? controller.nestedReplies
                                      : null,
                                  replyToMessageId: controller.replyToMessageId,
                                  setRepliedMessage:
                                      controller.setRepliedMessage),
                          ],
                        ),
                      )
                    : SizedBox(height: 8),
              ],
            ),
          );
        });
  }
}
