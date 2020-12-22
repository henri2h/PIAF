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
  @override
  Widget build(BuildContext context) {
    Event e = widget.event;
    SClient sclient = Matrix.of(context).sclient;
    return Padding(
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
                        padding: const EdgeInsets.all(15),
                        child: PostContent(e),
                      ),
                      if (sclient.sreactions.containsKey(e.eventId))
                        PostReactions(event: e),
                      PostFooter(event: e),
                    ],
                  ),
                ),
                if (sclient.sreplies.containsKey(e.eventId))
                  RepliesVue(event: e),
              ],
            )),
      ),
    );
  }
}

class RepliesVue extends StatelessWidget {
  const RepliesVue({Key key, @required this.event}) : super(key: key);
  final Event event;
  final String regex = "<mx-reply>(.*)<\/mx-reply>";
  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    Set<Event> sr = sclient.sreplies[event.eventId];
    if (sclient.sreplies == null) {
      return Text("error..");
    }

    return Container(
//      decoration: BoxDecoration(color: Colors.grey),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (Event revent in sr)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Transform.rotate(angle: math.pi, child: Icon(Icons.reply)),
                  SizedBox(width: 10),
                  CircleAvatar(
                    radius: 10,
                    backgroundImage: event.sender.avatarUrl == null
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
                  Text(
                      revent.formattedText.replaceFirst(new RegExp(regex), "")),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class PostReactions extends StatelessWidget {
  const PostReactions({Key key, @required this.event}) : super(key: key);
  final Event event;
  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    Set<Event> sr = sclient.sreactions[event.eventId];
    if (sclient.sreactions == null) {
      return Text("error..");
    }

    return Row(
      children: [
        for (Event revent in sr)
          Row(
            children: [Text(revent.content['m.relates_to']['key'])],
          ),
      ],
    );
  }
}

class PostFooter extends StatelessWidget {
  const PostFooter({Key key, this.event}) : super(key: key);
  final Event event;
  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      FlatButton(child: Text("react"), onPressed: () {}),
      if (event.canRedact) FlatButton(child: Text("edit"), onPressed: () {})
    ]);
  }
}

class PostHeader extends StatelessWidget {
  const PostHeader({Key key, this.event}) : super(key: key);
  final Event event;
  @override
  Widget build(BuildContext context) {
    final SClient client = Matrix.of(context).sclient;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: <Widget>[
          CircleAvatar(
            backgroundImage: event.sender.avatarUrl == null
                ? null
                : NetworkImage(
                    event.sender.avatarUrl.getThumbnail(
                      client,
                      width: 64,
                      height: 64,
                    ),
                  ),
          ),
          SizedBox(width: 10),
          Text(event.sender.displayName,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(" to ", style: TextStyle(fontSize: 20)),
          Text(event.room.name,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ]),
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
