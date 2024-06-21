import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:swipe_to/swipe_to.dart';

import '../../../config/matrix_types.dart';
import 'event_types/event_type_call_message.dart';
import 'event_types/event_type_encrypted.dart';
import 'event_types/event_type_poll_start.dart';
import 'event_types/event_type_room_message.dart';
import 'event_types/event_type_room_state.dart';
import 'event_widget.dart';

class PlainEventWidget extends StatelessWidget {
  const PlainEventWidget({
    super.key,
    required this.state,
  });

  final EventWidget state;

  @override
  Widget build(BuildContext context) {
    final event = state.ctx.event;

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
                onRightSwipe: state.onReply,
                child: EventTypeRoomMessage(state: state));

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
        return EventTypeRoomState(event);

      case EventTypes.Encryption:
        return EventTypeEncrypted(event: event);
      case MatrixEventTypes.pollStart:
        return EventTypePollStart(ctx: state.ctx);
      case MatrixEventTypes.pollResponse:
        return Container();
      case EventTypes.CallInvite:
        return EventTypeCallMessage(event, timeline: state.ctx.timeline);

      default:
    }
    // unknown event
    return EventTypeRoomState(event);
  }
}
