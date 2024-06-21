import 'dart:async';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/minestrix_chat.dart';

import 'event_type_builder.dart';

class RoomEventContext {
  final Event? prevEvent;
  final Event? nextEvent;
  Event event;
  final Event? oldEvent;
  final Timeline? timeline;
  final Set<Event>? reactions;
  final bool isDirectChat;
  final bool isLastMessage;
  final bool edited;
  Client get client => event.room.client;

  RoomEventContext(
      {required this.event,
      this.oldEvent,
      this.prevEvent,
      this.nextEvent,
      this.timeline,
      this.reactions,
      this.isDirectChat = false,
      this.isLastMessage = false,
      this.edited = false});

  bool get isNextEventFromSameId =>
      nextEvent?.type == EventTypes.Message &&
      nextEvent?.senderId == event.senderId;

  bool get isPreEventFromSameId =>
      prevEvent?.type == EventTypes.Message &&
      prevEvent?.senderId == event.senderId;

  bool get sentByUser => event.sentByUser;
}

/// A widget display the event and decripting it if needed
class EventWidget extends StatefulWidget {
  final RoomEventContext ctx;

  final GestureDragUpdateCallback? onReply;
  final void Function(Event reply)? onReplyEventPressed;
  final void Function(Offset)? onReact;

  final bool displayAvatar;
  final bool displayName;
  final bool addPaddingTop;

  final Stream<String>? onEventSelectedStream;
  const EventWidget({
    super.key,
    required this.ctx,
    this.onReact,
    this.onEventSelectedStream,
    this.onReply,
    this.displayAvatar = false,
    this.displayName = false,
    this.addPaddingTop = false,
    this.onReplyEventPressed,
  });

  @override
  EventWidgetState createState() => EventWidgetState();
}

class EventWidgetState extends State<EventWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ctx.event.messageType == MessageTypes.BadEncrypted) {
      return FutureBuilder<Event>(
          future: widget.ctx.event.room.client.encryption!.decryptRoomEvent(
              widget.ctx.event.roomId!, widget.ctx.event,
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
            if (snapshot.hasData) {
              widget.ctx.event = snapshot.data!;
            }

            return buildEventWithPadding(context);
          });
    }

    // then load the event
    return buildEventWithPadding(context);
  }

  Widget buildEventWithPadding(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: widget.addPaddingTop ? 16 : 3, right: 8),
      child: PlainEventWidget(state: widget),
    );
  }
}
