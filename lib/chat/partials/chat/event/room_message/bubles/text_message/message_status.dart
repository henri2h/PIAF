import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart';

class MessageStatus extends StatelessWidget {
  const MessageStatus({
    super.key,
    required this.edited,
    required this.colorPatch,
    required this.textTheme,
    required this.displayTime,
    required this.event,
    required this.displaySentIndicator,
  });

  final bool edited;
  final Color colorPatch;
  final TextStyle? textTheme;
  final bool displayTime;
  final Event event;
  final bool displaySentIndicator;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (edited) Icon(Icons.edit, color: colorPatch, size: 12),
        if (edited) const SizedBox(width: 2),
        if (edited)
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Text("edited", style: textTheme),
          ),
        if (displayTime)
          Text(DateFormat.Hm().format(event.originServerTs), style: textTheme),
        if (displaySentIndicator || event.status != EventStatus.synced)
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Builder(builder: (context) {
              IconData icon = Icons.error;
              String text = "Arggg";
              switch (event.status) {
                case EventStatus.removed:
                  break;
                case EventStatus.error:
                  // TODO: Handle this case.
                  break;
                case EventStatus.sending:
                  icon = Icons.flight_takeoff;
                  text = "Sending";
                  break;
                case EventStatus.sent:
                  icon = Icons.check_circle_outline;
                  text = "Sent";
                  break;
                case EventStatus.synced:
                  text = "Synced";
                  icon = Icons.check_circle;
                  break;
                case EventStatus.roomState:
                  // TODO: Handle this case.
                  break;
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: colorPatch, size: 12),
                  const SizedBox(width: 2),
                  Text(text, style: textTheme),
                ],
              );
            }),
          )
      ],
    );
  }
}
