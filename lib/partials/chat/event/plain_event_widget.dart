import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:swipe_to/swipe_to.dart';

import '../../../config/matrix_types.dart';
import '../../poll/poll_widget.dart';
import 'room_message/call_message_dispaly.dart';
import 'event_widget.dart';
import 'room_message/room_message_widget.dart';
import 'room_message/room_event_update_widget.dart';

class PlainEventWidget extends StatelessWidget {
  const PlainEventWidget({
    super.key,
    required this.eventWidgetState,
    required this.context,
    required this.event,
  });

  final EventWidget eventWidgetState;
  final BuildContext context;
  final Event event;

  @override
  Widget build(BuildContext context) {
    switch (event.type) {
      case EventTypes.Message:
      case EventTypes.Sticker:
      case EventTypes.Encrypted:
      case EventTypes.Redaction:
        switch (event.messageType) {
          case MessageTypes.Text:
          case MessageTypes.Emote:
          case MessageTypes.Image:
          case MessageTypes.Sticker:
          case MessageTypes.Notice:
          case MessageTypes.File:
          case MessageTypes.Audio:
          case MessageTypes.Video:
          case MessageTypes.BadEncrypted:
            return SwipeTo(
                onRightSwipe: eventWidgetState.onReply,
                child: RoomMessageWidget(
                    eventWidgetState: eventWidgetState, event: event));

          default:
            return Text("other message type : ${event.messageType}");
        }
      case EventTypes.RoomMember:
      case EventTypes.RoomName:
      case EventTypes.RoomJoinRules:
      case EventTypes.RoomTopic:
      case EventTypes.RoomAvatar:
      case EventTypes.HistoryVisibility:
      case EventTypes.RoomPowerLevels:
      case EventTypes.RoomCanonicalAlias:
      case EventTypes.GuestAccess:
      case EventTypes.RoomCreate:
        return RoomEventUpdateWidget(event);

      case EventTypes.Encryption:
        return Card(
            child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.enhanced_encryption),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("End-To-End encryption activated"),
                      Text(
                          event.content.tryGet<String>("algorithm") ??
                              "An error happened - no algorithm given",
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
      case MatrixEventTypes.pollStart:
        if (event.redacted) {
          return Text(
              "${event.sender.displayName ?? event.sender.senderId} redacted a poll");
        }
        if (eventWidgetState.timeline != null) {
          return PollWidget(event: event, timeline: eventWidgetState.timeline!);
        }
        break;
      case MatrixEventTypes.pollResponse:
        return Container();
      case EventTypes.CallInvite:
        if (eventWidgetState.timeline != null) {
          return CallMessageDisplay(event,
              timeline: eventWidgetState.timeline!);
        }
        break;
      default:
    }
    // unknown event
    return RoomEventUpdateWidget(event);
  }
}
