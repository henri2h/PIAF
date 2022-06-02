import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/partials/matrix/reactions_list.dart';

import 'details/post_content.dart';
import 'details/post_reactions.dart';
import 'details/post_header.dart';
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
                    PostHeader(event: controller.post.event!),
                    PostContent(
                      controller.post.event!,
                      imageMaxHeight: 300,
                    ),
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
