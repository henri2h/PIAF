import 'dart:math';

import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:timeago/timeago.dart' as timeago;

class RepliesVue extends StatelessWidget {
  final Event event;
  final Set<Event> replies;
  final String regex = "(>(.*)\n)*\n";
  const RepliesVue({Key key, @required this.event, @required this.replies})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    // get replies
    SClient sclient = Matrix.of(context).sclient;
    int max = min(replies.length, 2);

    return Container(
//      decoration: BoxDecoration(color: Colors.grey),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (Event revent in replies.toList().sublist(0, max))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
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
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: MinesTrixUserImage(
                                    url: revent.sender.avatarUrl,
                                    width: 16,
                                    height: 16)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Card(
                                elevation: 0.3,
                                color: Color(0xfff6f6f6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(revent.sender.asUser.displayName,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700)),
                                          Text(
                                              " - " +
                                                  timeago.format(
                                                      revent.originServerTs),
                                              style: TextStyle(
                                                  color: Colors.black54,
                                                  fontWeight: FontWeight.w400)),
                                        ],
                                      ),
                                      SizedBox(height: 5),
                                      Text(revent.body
                                          .replaceFirst(new RegExp(regex), "")),
                                    ],
                                  ),
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
                            sclient.srooms[revent.roomId].timeline,
                            RelationshipTypes.reply)),
                  )
                ],
              ),
            ),
          if (replies.length > max)
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
  const ReplyBox({Key key, @required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController tc = TextEditingController();
    SClient sclient = Matrix.of(context).sclient;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          MinesTrixUserImage(url: sclient.userRoom.user.avatarUrl),
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
                await event.room.sendTextEvent(tc.text, inReplyTo: event);
                tc.clear();
              })
        ],
      ),
    );
  }
}
