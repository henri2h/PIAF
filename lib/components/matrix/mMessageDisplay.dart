import 'package:matrix/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:minestrix/components/matrix/mImage.dart';

class MessageDisplay extends StatelessWidget {
  final Event event;

  const MessageDisplay({
    Key key,
    @required this.event,
    this.widgetDisplay,
  }) : super(key: key);
  final Function widgetDisplay;

  Widget buildPage(BuildContext context, Event event) {
    switch (event.type) {
      case EventTypes.Message:
      case EventTypes.Encrypted:
        switch (event.messageType) {
          case MessageTypes.Text:
          case MessageTypes.Emote:
            if (widgetDisplay == null) {
              return MarkdownBody(data: event.body); // markdown support
            }

            return widgetDisplay(event.body);

          case MessageTypes.Image:
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarkdownBody(data: event.body),
                SizedBox(height: 10),
                MImage(event: event),
              ],
            );
          case MessageTypes.Video:
            return Text(event.body);

          default:
            return Text("other message type : " + event.messageType);
        }
        break;
      case EventTypes.RoomMember:
        String text = "";
        if (event.content.containsKey("displayname"))
          text = event.content["displayname"];
        return Text(text + " " + event.content["membership"]);
      case EventTypes.RoomCreate:
        return Card(
            child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text("🎉"),
              SizedBox(width: 10),
              Column(
                children: [
                  Text(event.content["creator"] + " created room"),
                ],
              ),
            ],
          ),
        ));
      case EventTypes.RoomName:
        return Card(
            child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Column(
                children: [
                  Text("New room name : " + event.content["name"]),
                ],
              ),
            ],
          ),
        ));
      case EventTypes.Encryption:
        return Card(
            child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.enhanced_encryption),
              SizedBox(width: 10),
              Column(
                children: [
                  Text("End-To-End encryption activated"),
                  Text(event.content["algorithm"]),
                ],
              ),
            ],
          ),
        ));
      default:
        return Text("Unknown event type " + event.type);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (event.messageType == MessageTypes.BadEncrypted) {
      return FutureBuilder(
          future: event.requestKey(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) return buildPage(context, snapshot.data);
            return LinearProgressIndicator();
          });
    }
    return buildPage(context, event);
  }
}
