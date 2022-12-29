import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/config/matrix_types.dart';

import 'details/post_content.dart';
import 'details/post_header.dart';
import 'details/post_replies.dart';
import 'post.dart';
import 'details/post_reaction_bar.dart';

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
              ? controller.post.getDisplayEventWithType(t, MatrixTypes.post)
              : controller.post;

          return LayoutBuilder(builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 500;

            final post = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // post content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isMobile) const Divider(),
                    PostHeader(
                        eventToEdit: controller.post, event: displayEvent),
                    if (!isMobile)
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
                        child: Divider(),
                      ),
                    if ([EventStatus.sent, EventStatus.synced]
                            .contains(controller.post.status) ==
                        false)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                            trailing: const Icon(Icons.message),
                            leading: const CircularProgressIndicator(),
                            title: const Text("Sending"),
                            subtitle: Text(controller.post.status
                                .toString()
                                .replaceAll("EventStatus.", ""))),
                      ),
                    PostContent(
                      displayEvent,
                      imageMaxHeight: 300,
                    ),
                    if (controller.shareEvent != null)
                      FutureBuilder<Event?>(
                          future: controller.shareEvent,
                          builder: (context, snap) {
                            if (snap.hasError) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error),
                                    const SizedBox(width: 4),
                                    Text(snap.error.toString()),
                                  ],
                                ),
                              );
                            }
                            if (!snap.hasData) {
                              return const CircularProgressIndicator();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
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
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ReactionBar(
                          controller: controller, isMobile: isMobile),
                    ),
                  ],
                ),
                (controller.replyToMessageId != null ||
                            controller.showReplies) &&
                        t != null
                    ? Column(
                        children: [
                          const Divider(),
                          if (controller.replyToMessageId != null ||
                              controller.showReplies)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: RepliesVue(
                                  timeline: t,
                                  event: controller.post,
                                  replies: (controller.showReplies &&
                                          controller.replies?.isNotEmpty ==
                                              true)
                                      ? controller.nestedReplies
                                      : null,
                                  replyToMessageId: controller.replyToMessageId,
                                  setRepliedMessage:
                                      controller.setRepliedMessage),
                            ),
                        ],
                      )
                    : const SizedBox(height: 8),
              ],
            );

            if (isMobile) {
              return post;
            }

            return Card(child: post);
          });
        });
  }
}
