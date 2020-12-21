import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/matrix/mImage.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:timeago/timeago.dart' as timeago;

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
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                PostHeader(event: e),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: PostContent(e),
                ),
                if (sclient.sreactions.containsKey(e.eventId))
                  PostReactions(event: e),
                PostFooter(event: e),
              ],
            )),
      ),
    );
  }
}

class PostReactions extends StatelessWidget {
  const PostReactions({
    Key key,@required this.event
  }) : super(key: key);
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
        for(Event revent in sr) Row(
          children: [
            Text(revent.content['m.relates_to']['key'])
          ],
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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
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
            ),
            Text(event.sender.displayName,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(" to ", style: TextStyle(fontSize: 20)),
            Text(event.room.name,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
        ),
        Row(
          children: [
            Text(timeago.format(event.originServerTs),
                style: TextStyle(fontWeight: FontWeight.bold)),
            if (event.type == EventTypes.Encrypted)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.enhanced_encryption),
              ),
          ],
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
            return Text(event.body);
          case MessageTypes.Image:
            return MImage(event: event);

          default:
            return Text("other message type");
        }
        break;
      default:
        return Text("Unknown event type");
    }
  }
}
