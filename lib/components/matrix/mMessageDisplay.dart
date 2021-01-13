import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:minestrix/components/matrix/mImage.dart';

class MessageDisplay extends StatelessWidget {
  final Event event;

  const MessageDisplay({
    Key key,
    @required this.event,
  }) : super(key: key);

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
