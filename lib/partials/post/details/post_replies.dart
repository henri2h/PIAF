import 'dart:math';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/chat/message_composer/matrix_message_composer.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'post_content.dart';

class RepliesVue extends StatefulWidget {
  final Event event;
  final Timeline timeline;
  final Set<Event> replies;
  final bool showEditBox;

  final void Function(bool value)? setReplyVisibility;
  RepliesVue({
    Key? key,
    required this.event,
    required this.replies,
    required this.timeline,
    this.showEditBox = false,
    this.setReplyVisibility,
  }) : super(key: key);

  @override
  RepliesVueState createState() => RepliesVueState();
}

class RepliesVueState extends State<RepliesVue> {
  int tMax = 2;

  Future<void> overrideTextSending(String text) async {
    Map<String, dynamic> content = {
      "msgtype": MessageTypes.Text,
      "body": text,
      "m.relates_to": {
        "rel_type": MatrixTypes.threadRelation,
        "event_id": widget.event.eventId
      }
    };
    await widget.event.room.sendEvent(content);
  }

  @override
  Widget build(BuildContext context) {
    Client? client = Matrix.of(context).client;

    List<Event> directRepliesToEvent =
        client.getPostReactions(widget.replies).toList();

    int max = min(directRepliesToEvent.length, tMax);

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showEditBox == true)
            MatrixMessageComposer(
                client: client,
                room: widget.event.room,
                onReplyTo: widget.event,
                hintText: "Reply",
                allowSendingPictures: false,
                overrideSending: overrideTextSending,
                onSend: () => widget.setReplyVisibility?.call(false)),
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
                  if (false)
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: RepliesVue(
                          event: revent,
                          timeline: widget.timeline,
                          replies: widget.replies),
                    )
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
