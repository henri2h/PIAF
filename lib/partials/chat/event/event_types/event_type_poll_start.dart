import 'package:flutter/material.dart';

import '../../../poll/poll_widget.dart';
import '../event_widget.dart';

class EventTypePollStart extends StatelessWidget {
  const EventTypePollStart({super.key, required this.ctx});

  final RoomEventContext ctx;

  @override
  Widget build(BuildContext context) {
    if (ctx.event.redacted) {
      return Text(
          "${ctx.event.sender.displayName ?? ctx.event.sender.senderId} redacted a poll");
    }
    if (ctx.timeline != null) {
      return PollWidget(event: ctx.event, timeline: ctx.timeline!);
    }
    return const Text("error");
  }
}
