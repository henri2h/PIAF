import 'package:emoji_picker/emoji_picker.dart';
import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:minestrix/components/matrix/mImage.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'dart:math' as math;

class Post extends StatefulWidget {
  Post({Key key, @required this.event}) : super(key: key);
  final Event event;

  @override
  _PostState createState() => _PostState();
}

class _PostState extends State<Post> with SingleTickerProviderStateMixin {
  void replyButtonClick() {
    setState(() {
      showReplyBox = !showReplyBox;
    });
  }

  bool showReplyBox = false;
  @override
  Widget build(BuildContext context) {
    Event e = widget.event;
    SClient sclient = Matrix.of(context).sclient;

    Timeline t = sclient.timelines[e.roomId];

    Set<Event> replies = e.aggregatedEvents(t, RelationshipTypes.Reply);
    Set<Event> reactions = e.aggregatedEvents(t, RelationshipTypes.Reaction);

    return StreamBuilder<Object>(
      stream: e.room.onUpdate.stream,
      builder: (context, snapshot) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(5),
          child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
              ),
              //padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // post content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PostHeader(event: e),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: PostContent(e),
                        ),
                        if (reactions.isNotEmpty)
                          PostReactions(event: e, reactions: reactions),
                        PostFooter(
                            event: e, replyButtonClick: replyButtonClick),
                      ],
                    ),
                  ),
                  if (showReplyBox) ReplyBox(event: e),
                  if (replies.isNotEmpty)
                    RepliesVue(event: e, replies: replies),
                ],
              )),
        ),
      ),
    );
  }
}

class ReplyBox extends StatelessWidget {
  const ReplyBox({Key key, @required this.event}) : super(key: key);
  final Event event;

  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    TextEditingController tc = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 10,
            backgroundImage: event.sender.avatarUrl == null
                ? null
                : NetworkImage(
                    sclient.userRoom.user.avatarUrl.getThumbnail(
                      sclient,
                      width: 16,
                      height: 16,
                    ),
                  ),
          ),
          SizedBox(width: 10),
          Expanded(
              child: TextField(
            controller: tc,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
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

class RepliesVue extends StatelessWidget {
  const RepliesVue({Key key, @required this.event, @required this.replies})
      : super(key: key);
  final Event event;
  final Set<Event> replies;
  final String regex = "(.*)\n(.*)\n";
  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    // get replies

    return Container(
//      decoration: BoxDecoration(color: Colors.grey),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (Event revent in replies)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.rotate(
                            angle: math.pi, child: Icon(Icons.reply)),
                        SizedBox(width: 10),
                        CircleAvatar(
                          radius: 10,
                          backgroundImage: revent.sender.avatarUrl == null
                              ? null
                              : NetworkImage(
                                  revent.sender.avatarUrl.getThumbnail(
                                    sclient,
                                    width: 16,
                                    height: 16,
                                  ),
                                ),
                        ),
                        SizedBox(width: 10),
                        Flexible(
                          child: Text(
                              revent.body.replaceFirst(new RegExp(regex), "")),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20),
                  Text(timeago.format(revent.originServerTs),
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class PostReactions extends StatelessWidget {
  const PostReactions({Key key, @required this.event, @required this.reactions})
      : super(key: key);
  final Event event;
  final Set<Event> reactions;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (Event revent in reactions)
          Row(
            children: [Text(revent.content['m.relates_to']['key'])],
          ),
      ],
    );
  }
}

class PostFooter extends StatelessWidget {
  const PostFooter(
      {Key key, @required this.event, @required this.replyButtonClick})
      : super(key: key);

  final Event event;
  final Function replyButtonClick;

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          FlatButton(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.insert_emoticon, size: 15),
                  SizedBox(width: 2),
                  Text("React"),
                ],
              ),
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
                await event.room.sendReaction(event.eventId, emoji.emoji);
              }),
          FlatButton(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.reply, size: 15),
                  SizedBox(width: 2),
                  Text("reply"),
                ],
              ),
              onPressed: replyButtonClick),
          if (event.canRedact)
            FlatButton(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.edit, size: 15),
                    SizedBox(width: 2),
                    Text("edit"),
                  ],
                ),
                onPressed: () {})
        ]);
  }
}

class PostHeader extends StatelessWidget {
  const PostHeader({Key key, this.event}) : super(key: key);
  final Event event;
  @override
  Widget build(BuildContext context) {
    final SClient sclient = Matrix.of(context).sclient;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: event.sender.avatarUrl == null
                    ? null
                    : NetworkImage(
                        event.sender.avatarUrl.getThumbnail(
                          sclient,
                          width: 64,
                          height: 64,
                        ),
                      ),
              ),
              SizedBox(width: 10),
              Flexible(
                child: Wrap(children: <Widget>[
                  Text(event.sender.displayName,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(" to ", style: TextStyle(fontSize: 20)),
                  FutureBuilder<String>(
                      future: sclient.getRoomDisplayName(event.room),
                      builder: (context, AsyncSnapshot<String> name) {
                        if (name.hasData) {
                          return Text(name.data,
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold));
                        }
                        return Text("Loading...");
                      })
                ]),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Text(timeago.format(event.originServerTs),
                  style: TextStyle(fontWeight: FontWeight.bold)),
              if (event.type == EventTypes.Encrypted)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.enhanced_encryption),
                ),
            ],
          ),
        )
      ],
    );
  }
}

class PostContent extends StatelessWidget {
  const PostContent(
    this.event, {
    Key key,
  }) : super(key: key);
  final Event event;
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            PostDecoder(event: event),
          ]),
    );
  }
}

class PostDecoder extends StatelessWidget {
  const PostDecoder({
    Key key,
    @required this.event,
  }) : super(key: key);

  final Event event;

  @override
  Widget build(BuildContext context) {
    switch (event.type) {
      case EventTypes.Message:
      case EventTypes.Encrypted:
        switch (event.messageType) {
          case MessageTypes.Text:
          case MessageTypes.Emote:
            return MarkdownBody(data: event.body); // markdown support
          case MessageTypes.Image:
            return MImage(event: event);
          case MessageTypes.Video:
            return Text(event.body);

          default:
            return Text("other message type : " + event.messageType);
        }
        break;
      default:
        return Text("Unknown event type");
    }
  }
}
