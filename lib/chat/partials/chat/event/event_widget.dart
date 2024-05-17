import 'dart:async';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'plain_event_widget.dart';

/// A widget display the event and decripting it if needed
class EventWidget extends StatefulWidget {
  final Event event;
  final Timeline? timeline;

  final Set<Event>? reactions;

  final Client? client;

  final GestureDragUpdateCallback? onReply;
  final void Function(Event reply)? onReplyEventPressed;
  final void Function(Offset)? onReact;

  final bool displayAvatar;
  final bool displayName;
  final bool addPaddingTop;
  final bool edited;
  final bool isLastMessage;
  final bool isDirectChat;

  final Stream<String>? onEventSelectedStream;
  const EventWidget(
      {super.key,
      required this.event,
      required this.client,
      this.reactions,
      this.onReact,
      this.timeline,
      this.onEventSelectedStream,
      this.onReply,
      this.isLastMessage = false,
      this.displayAvatar = false,
      this.displayName = false,
      this.addPaddingTop = false,
      this.edited = false,
      this.onReplyEventPressed,
      this.isDirectChat = false});

  @override
  EventWidgetState createState() => EventWidgetState();
}

class EventWidgetState extends State<EventWidget> {
  @override
  void initState() {
    super.initState();
  }

  bool hover = false;

  @override
  Widget build(BuildContext context) {
    if (widget.event.messageType == MessageTypes.BadEncrypted) {
      return FutureBuilder<Event>(
          future: widget.event.room.client.encryption!.decryptRoomEvent(
              widget.event.roomId!, widget.event,
              store: true),
          builder: (BuildContext context, snapshot) {
            if (snapshot.hasError) {
              return const Row(
                children: [
                  Icon(Icons.error),
                  SizedBox(
                    width: 10,
                  ),
                  Text("Could not load encrypted message"),
                ],
              );
            }
            return buildMouseRegion(context, snapshot.data ?? widget.event);
          });
    }

    // then load the event
    return buildMouseRegion(context, widget.event);
  }

  MouseRegion buildMouseRegion(BuildContext context, Event event) {
    return MouseRegion(
      child: Padding(
        padding: EdgeInsets.only(top: widget.addPaddingTop ? 16 : 3, right: 8),
        child: PlainEventWidget(
            eventWidgetState: widget, context: context, event: event),
      ),
      onEnter: (_) => setState(() {
        hover = true;
      }),
      onExit: (_) => setState(() {
        hover = false;
      }),
    );
  }
}
