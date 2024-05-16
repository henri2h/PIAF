import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/chat/minestrix_chat.dart';
import 'package:piaf/chat/partials/matrix/matrix_image_avatar.dart';
import 'package:piaf/chat/utils/matrix_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'post_content.dart';

class PostReplies extends StatelessWidget {
  final Event event;
  final Timeline? timeline;
  final Set<Event> replies;

  const PostReplies(
      {super.key,
      required this.event,
      required this.replies,
      required this.timeline});

  @override
  Widget build(BuildContext context) {
    Client? client = Matrix.of(context).client;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (Event localEvent
            in replies.toList()
              ..sort((a, b) => b.originServerTs.compareTo(a.originServerTs)))
          FutureBuilder<User?>(
              future: localEvent.fetchSenderUser(),
              builder: (context, snap) {
                final sender =
                    snap.data ?? localEvent.senderFromMemoryOrFallback;

                Set<Event>? localReplies;
                if (timeline != null) {
                  localReplies = localEvent.getReplies(timeline!);
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 2.0, horizontal: 20.0),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    child: MatrixImageAvatar(
                                      client: client,
                                      url: sender.avatarUrl,
                                      defaultText: sender.calcDisplayname(),
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      width: 32,
                                      height: 32,
                                    )),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6, horizontal: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          children: [
                                            Text(sender.calcDisplayname(),
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            Text(
                                                " - ${timeago.format(localEvent.originServerTs)}",
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w400)),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        PostContent(
                                            timeline != null
                                                ? localEvent
                                                    .getDisplayEvent(timeline!)
                                                : localEvent,
                                            disablePadding: true,
                                            imageMaxHeight: 200),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (localReplies != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: PostReplies(
                              event: localEvent,
                              timeline: timeline,
                              replies: localReplies),
                        ),
                    ],
                  ),
                );
              }),
      ],
    );
  }
}
