import 'dart:math';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/chat/message_composer/matrix_message_composer.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/utils/social/posts/model/social_item.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'post_content.dart';

class RepliesVue extends StatefulWidget {
  final Event event;
  final Event postEvent;
  final Timeline timeline;
  final Map<Event, dynamic>? replies;
  final String? replyToMessageId;

  final void Function(String? value) setRepliedMessage;
  RepliesVue({
    Key? key,
    required this.event,
    required this.postEvent,
    required this.replies,
    required this.timeline,
    required this.replyToMessageId,
    required this.setRepliedMessage,
  }) : super(key: key);

  @override
  RepliesVueState createState() => RepliesVueState();
}

class RepliesVueState extends State<RepliesVue> {
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

    int max = min(directRepliesToEvent.length, tMax);

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.replyToMessageId == widget.event.eventId)
            MatrixMessageComposer(
                client: client,
                room: widget.event.room,
                hintText: "Reply",
                allowSendingPictures: false,
                overrideSending: (String text) =>
                    overrideTextSending(text, replyTo: widget.event),
                onSend: () => widget.setRepliedMessage(null)),
          for (Event revent
              in directRepliesToEvent.take(max).toList()
                ..sort((a, b) => b.originServerTs.compareTo(a.originServerTs)))
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 2.0, horizontal: 20.0),
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
                                  url: revent.sender.avatarUrl,
                                  defaultText: revent.sender.calcDisplayname(),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                            revent.sender.asUser.displayName
                                                .toString(),
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700)),
                                        Text(
                                            " - " +
                                                timeago.format(
                                                    revent.originServerTs),
                                            style: TextStyle(
                                                fontWeight: FontWeight.w400)),
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                    PostContent(
                                        revent.getDisplayEvent(widget.timeline),
                                        disablePadding: true,
                                        imageMaxHeight: 200),
                                    if (widget.replyToMessageId !=
                                        revent.eventId)
                                      TextButton(
                                          onPressed: () =>
                                              widget.setRepliedMessage(
                                                  revent.eventId),
                                          child: Text("Reply"))
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
                      child: RepliesVue(
                          event: revent,
                          postEvent: widget.postEvent,
                          timeline: widget.timeline,
                          replies: widget.replies![revent],
                          setRepliedMessage: widget.setRepliedMessage,
                          replyToMessageId: widget.replyToMessageId),
                    ),
                ],
              ),
            ),
          if (directRepliesToEvent.length > max)
            Center(
                child: MaterialButton(
                    child: Text("Show more"),
                    onPressed: () {
                      setState(() {
                        tMax = max + 5;
                      });
                    }))
        ],
      ),
    );
  }
}
