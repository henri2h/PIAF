import 'package:flutter/material.dart';
import 'package:minestrix_chat/utils/extensions/minestrix/model/calendar_event_model.dart';

class DurationWidget extends StatelessWidget {
  const DurationWidget({
    Key? key,
    required this.calendarEvent,
  }) : super(key: key);

  final CalendarEvent calendarEvent;

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      final diff = calendarEvent.end!.difference(calendarEvent.start!);
      String text = "No duration";
      if (diff.inHours != 0) {
        text = "${diff.inHours} hour(s)";
      }
      if (diff.inMinutes.abs() > 0) {
        if (diff.inMinutes >= 60) {
          text += " and ${diff.inMinutes % 60} minute(s)";
        } else {
          text = "${diff.inMinutes} minute(s)";
        }
      }

      return ListTile(
          title: const Text("Duration"),
          subtitle: Text(text),
          leading: const Icon(Icons.date_range));
    });
  }
}
