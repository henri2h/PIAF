import 'dart:math';

import 'package:emoji_picker/emoji_picker.dart';
import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/matrix/mMessageDisplay.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:timeago/timeago.dart' as timeago;

class Post extends StatefulWidget {
  final Event event;
  Post({Key key, @required this.event}) : super(key: key);

  @override
  _PostState createState() => _PostState();
}

class PostContent extends StatelessWidget {
  final Event event;
  const PostContent(
    this.event, {
    Key key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            MessageDisplay(event: event),
          ]),
    );
  }
}

class PostHeader extends StatelessWidget {
  final Event event;
  const PostHeader({Key key, this.event}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final SClient sclient = Matrix.of(context).sclient;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              MatrixUserImage(
                  url: event.sender.avatarUrl, width: 45, height: 45),
              SizedBox(width: 15),
              Flexible(
                child: FutureBuilder<String>(
                    future: sclient.getRoomDisplayName(event.room),
                    builder: (context, AsyncSnapshot<String> name) {
                      if (name.hasData) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.sender.displayName,
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                Text("to",
                                    style: TextStyle(color: Colors.grey[600])),
                                SizedBox(width: 2),
                                Text(name.data,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400)),
                              ],
                            ),
                            Text(timeago.format(event.originServerTs),
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    color: Colors.grey[600])),
                          ],
                        );
                      }
                      return Text(event.sender.displayName,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold));
                    }),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              if (event.type == EventTypes.Encrypted)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.enhanced_encryption),
                ),
              PopupMenuButton<String>(
                  itemBuilder: (_) => [
                        if (event.canRedact)
                          PopupMenuItem(
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 10),
                                  Text("Edit post"),
                                ],
                              ),
                              value: "edit"),
                        if (event.canRedact)
                          PopupMenuItem(
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 10),
                                  Text("Delete post",
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                              value: "delete")
                      ],
                  child: Icon(Icons.more_horiz),
                  onSelected: (String action) async {
                    switch (action) {
                      case "delete":
                        await event.redact();
                        break;
                      default:
                    }
                  })
            ],
          ),
        )
      ],
    );
  }
}

class PostReactions extends StatelessWidget {
  final Event event;
  final Set<Event> reactions;
  const PostReactions({Key key, @required this.event, @required this.reactions})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    Map<String, int> keys = new Map<String, int>();
    for (Event revent in reactions) {
      String key = revent.content['m.relates_to']['key'];
      keys.update(key, (value) => value + 1, ifAbsent: () => 1);
    }
    return Row(
      children: [
        for (MapEntry<String, int> key in keys.entries)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(children: [
                  Text(key.key),
                  SizedBox(width: 10),
                  Text(key.value.toString())
                ]),
              ),
            ),
          ),
      ],
    );
  }
}

class ReactionItemWidget extends StatelessWidget {
  final Widget child;
  const ReactionItemWidget(
    this.child, {
    Key key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(5),
      color: Colors.white,
      elevation: 2,
      child: Padding(padding: const EdgeInsets.all(6), child: child),
    );
  }
}

class RepliesVue extends StatelessWidget {
  final Event event;
  final Set<Event> replies;
  final String regex = "(>(.*)\n)*\n";
  const RepliesVue({Key key, @required this.event, @required this.replies})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    // get replies
    int max = min(replies.length, 2);

    return Container(
//      decoration: BoxDecoration(color: Colors.grey),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (Event revent in replies.toList().sublist(0, max))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: MatrixUserImage(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
    SClient sclient = Matrix.of(context).sclient;
    TextEditingController tc = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          MatrixUserImage(url: event.sender.avatarUrl),
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

class _PostState extends State<Post> with SingleTickerProviderStateMixin {
  bool showReplyBox = false;

  @override
  Widget build(BuildContext context) {
    Event e = widget.event;
    SClient sclient = Matrix.of(context).sclient;

    Timeline t = sclient.srooms[e.roomId].timeline;

    Set<Event> replies = e.aggregatedEvents(t, RelationshipTypes.Reply);
    Set<Event> reactions = e.aggregatedEvents(t, RelationshipTypes.Reaction);

    return StreamBuilder<Object>(
      stream: e.room.onUpdate.stream,
      builder: (context, snapshot) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // post content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PostHeader(event: e),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: PostContent(e),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FlatButton(
                      onPressed: () async {
                        Emoji emoji = await showModalBottomSheet(
                            context: context,
                            builder: (context) => Column(children: [
                                  EmojiPicker(
                                    onEmojiSelected: (emoji, category) {
                                      Navigator.of(context).pop<Emoji>(emoji);
                                    },
                                  ),
                                ]));
                        await e.room.sendReaction(e.eventId, emoji.emoji);
                      },
                      child: reactions.isNotEmpty
                          ? PostReactions(event: e, reactions: reactions)
                          : ReactionItemWidget(
                              Row(children: [
                                Icon(Icons.emoji_emotions, size: 16),
                                SizedBox(width: 10),
                                Text("0")
                              ]),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FlatButton(
                        onPressed: replyButtonClick,
                        child: ReactionItemWidget(
                          Row(children: [
                            Icon(Icons.reply, size: 16),
                            SizedBox(width: 10),
                            Text("")
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              //color: Color(0xfff6f6f6),
              child: Column(
                children: [
                  if (showReplyBox) ReplyBox(event: e),
                  if (replies.isNotEmpty)
                    RepliesVue(event: e, replies: replies),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void replyButtonClick() {
    setState(() {
      showReplyBox = !showReplyBox;
    });
  }
}
