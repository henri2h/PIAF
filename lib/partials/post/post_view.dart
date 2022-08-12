import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/utils/events/event_extension.dart';

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
              ? controller.post.event!
                  .getDisplayEventWithType(t, MatrixTypes.post)
              : controller.post.event!;

          return LayoutBuilder(builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 500;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // post content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(),
                    PostHeader(
                        eventToEdit: controller.post.event!,
                        event: displayEvent),
                    Divider(),
                    if (controller.post.event!.status != EventStatus.synced)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child:
                            Text("Not sent ${controller.post.event!.status}"),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                    Divider(),
                    ReactionBar(controller: controller, isMobile: isMobile),
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
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: RepliesVue(
                                    timeline: t,
                                    event: controller.post.event!,
                                    replies: (controller.showReplies &&
                                            controller.replies?.isNotEmpty ==
                                                true)
                                        ? controller.nestedReplies
                                        : null,
                                    replyToMessageId:
                                        controller.replyToMessageId,
                                    setRepliedMessage:
                                        controller.setRepliedMessage),
                              ),
                          ],
                        ),
                      )
                    : SizedBox(height: 8),
              ],
            );
          });
        });
  }
}
