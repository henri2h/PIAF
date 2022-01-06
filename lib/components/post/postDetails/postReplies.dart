import 'dart:math';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:minestrix_chat/partials/chat/matrix_message_composer.dart';

class RepliesVue extends StatefulWidget {
  final Event event;
  final Set<Event> replies;
  final String regex = "(>(.*)\n)*\n"; // TODO : find a better way
  final bool showEditBox;
  RepliesVue({
    Key? key,
    required this.event,
    required this.replies,
    this.showEditBox = false,
  }) : super(key: key);

  @override
  _RepliesVueState createState() => _RepliesVueState();
}

class _RepliesVueState extends State<RepliesVue> {
  bool? showEditBox = null;
  bool? lastShowEditBox = null;

  @override
  Widget build(BuildContext context) {
    // edit inner value when widget value change
    if (lastShowEditBox != widget.showEditBox) showEditBox = widget.showEditBox;

    // get replies
    MinestrixClient? sclient = Matrix.of(context).sclient;
    int max = min(widget.replies.length, 2);

    return Container(
//      decoration: BoxDecoration(color: Colors.grey),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showEditBox == true)
            MatrixMessageComposer(
                client: sclient!,
                room: widget.event.room,
                onReplyTo: widget.event,
                hintText: "Reply",
                onSend: () {
                  setState(() {
                    showEditBox = false;
                  });
                }),
          if (showEditBox == true)
            ReplyBox(
                event: widget.event,
                onMessageSend: () {
                  setState(() {
                    showEditBox = false;
                  });
                }),
          for (Event revent in widget.replies.toList().sublist(0, max))
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
                                    Text(revent.body.replaceFirst(
                                        new RegExp(widget.regex), "")),
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
                        replies: revent.aggregatedEvents(
                            sclient!.srooms[revent.roomId!]!.timeline!,
                            RelationshipTypes.reply)),
                  )
                ],
              ),
            ),
          if (widget.replies.length > max)
            Center(
                child:
                    MaterialButton(child: Text("load more"), onPressed: () {}))
        ],
      ),
    );
  }
}

class ReplyBox extends StatelessWidget {
  final Event event;
  final Function? onMessageSend;

  const ReplyBox({Key? key, required this.event, this.onMessageSend})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController tc = TextEditingController();
    MinestrixClient sclient = Matrix.of(context).sclient!;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          MatrixUserImage(
              client: sclient,
              url: sclient.userRoom!.user.avatarUrl,
              width: 38,
              thumnail: true,
              height: 38),
          SizedBox(width: 10),
          Expanded(
              child: TextField(
            controller: tc,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              filled: true,
              fillColor: Color(0xf5f8fc),
              contentPadding: EdgeInsets.all(15),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              labelText: 'Reply',
            ),
          )),
          SizedBox(width: 10),
          IconButton(
              icon: Icon(Icons.send),
              onPressed: () async {
                Map<String, dynamic> content = {
                  "msgtype": MessageTypes.Text,
                  "body": tc.text,
                  "m.relates_to": {
                    "rel_type": MinestrixClient.elementThreadEventType,
                    "event_id": event.eventId
                  }
                };
                await event.room.sendEvent(content);
                //await event.room.sendTextEvent(tc.text, inReplyTo: event);
                tc.clear();

                // send event
                onMessageSend!();
              })
        ],
      ),
    );
  }
}
