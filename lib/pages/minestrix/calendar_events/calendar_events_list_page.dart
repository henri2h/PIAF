import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/utils/social/calendar_events/calendar_events_extension.dart';

import '../../../partials/calendar_events/calendar_events_card.dart';
import '../../../partials/components/layouts/customHeader.dart';

class CalendarEventListPage extends StatefulWidget {
  const CalendarEventListPage({Key? key}) : super(key: key);

  @override
  State<CalendarEventListPage> createState() => _CalendarEventListPageState();
}

class _CalendarEventListPageState extends State<CalendarEventListPage> {
  @override
  Widget build(BuildContext context) {
    final Client sclient = Matrix.of(context).client;
    return ListView(children: [
      CustomHeader(title: "Calendar events"),
      for (Room room in sclient.calendarEvents)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CalendarEventCard(room: room),
        ),
      if (sclient.calendarEvents.isEmpty) Text("No event found")
    ]);
  }
}