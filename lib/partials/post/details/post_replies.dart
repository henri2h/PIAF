import 'dart:math';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/chat/message_composer/matrix_message_composer.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/utils/social/posts/model/social_item.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'post_content.dart';

class RepliesVue extends StatelessWidget {
  final Event event;
  final bool enableMore;
  final Timeline? timeline;
  final Map<Event, dynamic>? replies;
  final String? replyToMessageId;

  final void Function(String? value) setRepliedMessage;
  const RepliesVue(
      {Key? key,
      required this.event,
      required this.replies,
      required this.timeline,
      required this.replyToMessageId,
      required this.setRepliedMessage,
      this.enableMore = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepliesVueRecursive(
      timeline: timeline,
      event: event,
      postEvent: event,
      enableMore: enableMore,
      replyToMessageId: replyToMessageId,
      replies: replies,
      setRepliedMessage: setRepliedMessage,
    );
  }
}

class RepliesVueRecursive extends StatefulWidget {
  final Event event;
  final bool enableMore;
  final Event postEvent;
  final Timeline? timeline;
  final Map<Event, dynamic>? replies;
  final String? replyToMessageId;

  final void Function(String? value) setRepliedMessage;
  const RepliesVueRecursive(
      {Key? key,
      required this.event,
      required this.postEvent,
      required this.replies,
      required this.timeline,
      required this.replyToMessageId,
      required this.setRepliedMessage,
      this.enableMore = true})
      : super(key: key);

  @override
  RepliesVueRecursiveState createState() => RepliesVueRecursiveState();
}

class RepliesVueRecursiveState extends State<RepliesVueRecursive> {
  int tMax = 2;

  Future<void> overrideTextSending(String text, {Event? replyTo}) async {
    final sp = SocialItem();
    sp.postText = text;

    final result = sp.toJson()
      ..addAll({
        "m.relates_to": {
          "rel_type": MatrixTypes.threadRelation,
          "event_id": widget.postEvent.eventId,
          "m.in_reply_to": {if (replyTo != null) "event_id": replyTo.eventId}
        }
      });

    await widget.event.room.sendEvent(result, type: MatrixTypes.post);
  }

  @override
  Widget build(BuildContext context) {
    Client? client = Matrix.of(context).client;

    List<Event> directRepliesToEvent = widget.replies != null
        ? client.getPostReactions(widget.replies!.keys).toList()
        : [];

    int max = widget.enableMore
        ? min(directRepliesToEvent.length, tMax)
        : directRepliesToEvent.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.replyToMessageId == widget.event.eventId)
          MatrixMessageComposer(
              client: client,
              room: widget.event.room,
              enableAutoFocusOnDesktop: false,
              hintText: "Reply",
              allowSendingPictures: false,
              overrideSending: (String text) =>
                  overrideTextSending(text, replyTo: widget.event),
              onSend: () => widget.setRepliedMessage(null)),
        for (Event revent
            in directRepliesToEvent.take(max).toList()
              ..sort((a, b) => b.originServerTs.compareTo(a.originServerTs)))
          FutureBuilder<User?>(
              future: revent.fetchSenderUser(),
              builder: (context, snap) {
                final sender = snap.data ?? revent.senderFromMemoryOrFallback;
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
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6),
                                    child: MatrixImageAvatar(
                                      client: client,
                                      url: sender.avatarUrl,
                                      defaultText: sender.calcDisplayname(),
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
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
                                            Text(
                                                sender.asUser.displayName
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            Text(
                                                " - ${timeago.format(revent
                                                        .originServerTs)}",
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w400)),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        PostContent(
                                            widget.timeline != null
                                                ? revent.getDisplayEvent(
                                                    widget.timeline!)
                                                : revent,
                                            disablePadding: true,
                                            imageMaxHeight: 200),
                                        if (widget.replyToMessageId !=
                                            revent.eventId)
                                          TextButton(
                                              onPressed: () =>
                                                  widget.setRepliedMessage(
                                                      revent.eventId),
                                              child: const Text("Reply"))
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (widget.replies![revent] != null ||
                          widget.replyToMessageId == revent.eventId)
                        Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: RepliesVueRecursive(
                              event: revent,
                              postEvent: widget.postEvent,
                              timeline: widget.timeline,
                              enableMore: widget.enableMore,
                              replies: widget.replies![revent],
                              setRepliedMessage: widget.setRepliedMessage,
                              replyToMessageId: widget.replyToMessageId),
                        ),
                    ],
                  ),
                );
              }),
        if (directRepliesToEvent.length > max)
          Center(
              child: MaterialButton(
                  child: const Text("Show more"),
                  onPressed: () {
                    setState(() {
                      tMax = max + 5;
                    });
                  }))
      ],
    );
  }
}
