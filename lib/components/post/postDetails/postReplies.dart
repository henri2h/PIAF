import 'dart:math';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/post/postDetails/postContent.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:minestrix_chat/partials/chat/matrix_message_composer.dart';

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
  _RepliesVueState createState() => _RepliesVueState();
}

class _RepliesVueState extends State<RepliesVue> {
  int tMax = 10;

  @override
  Widget build(BuildContext context) {
    // get replies
    MinestrixClient? sclient = Matrix.of(context).sclient;

    List<Event> directRepliesToEvent = widget.replies.where((element) {
      /*
                Here we are doing a bit of a hack. In input, we have all the events with a io.element.thread relation.
                However if we reply to a message in this stread, it will still have a reference 'rel_type' of io.element.thread
                to the main event. So we filter the event according to the ["m.relates_to"]["m.in_reply_to"]["event_id"]
                 */
      // get the references to this ev of event but not not event with a different m.in_reply_to

      Map<String, dynamic>? relates_to = element.content["m.relates_to"];
      if (relates_to == null) {
        print("null");
        return false;
      }

      if (relates_to.containsKey("m.in_reply_to") == true) {
        String val = relates_to["m.in_reply_to"]["event_id"];
        if (val != widget.event.eventId) {
          return false;
        } else {
          return true;
        }
      } else {
        // We are displaying the direct comment of post
        if (relates_to["event_id"] == widget.event.eventId) {
          return true;
        } else {
          // it's a reply to a comment of the post
          // so we don't redisplay the direct comments
          return false;
        }
      }
    }).toList();

    int max = min(directRepliesToEvent.length, tMax);
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showEditBox == true)
            MatrixMessageComposer(
                client: sclient!,
                room: widget.event.room,
                onReplyTo: widget.event,
                hintText: "Reply",
                allowSendingPictures: false,
                overrideSending: (String text) async {
                  Map<String, dynamic> content = {
                    "msgtype": MessageTypes.Text,
                    "body": text,
                    "m.relates_to": {
                      "rel_type": MinestrixClient.elementThreadEventType,
                      "event_id": widget.event.eventId
                    }
                  };
                  await widget.event.room.sendEvent(content);
                },
                onSend: () {
                  widget.setReplyVisibility?.call(false);
                }),
          for (Event revent
              in directRepliesToEvent.sublist(0, max)
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
                                child: MatrixUserImage(
                                  client: sclient,
                                  url: revent.sender.avatarUrl,
                                  defaultText: revent.sender.calcDisplayname(),
                                  backgroundColor: Colors.blue,
                                  width: 32,
                                  height: 32,
                                  thumnail: true,
                                  rounded: true,
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
                                    PostContent(revent, imageMaxHeight: 200),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 50.0),
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
                    child: Text("load more"),
                    onPressed: () {
                      setState(() {
                        tMax = max + 10;
                      });
                    }))
        ],
      ),
    );
  }
}
