import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/calendarEvents/calendarEventsCard.dart';
import 'package:minestrix/partials/components/layouts/customHeader.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix_chat/utils/social/calendar_events/calendar_events_extension.dart';

class CalendarEventListPage extends StatefulWidget {
  const CalendarEventListPage({Key? key}) : super(key: key);

  @override
  State<CalendarEventListPage> createState() => _CalendarEventListPageState();
}

class _CalendarEventListPageState extends State<CalendarEventListPage> {
  @override
  Widget build(BuildContext context) {
    final MinestrixClient sclient = Matrix.of(context).sclient!;
    return ListView(children: [
      CustomHeader("Calendar events"),
      for (Room room in sclient.calendarEvents)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CalendarEventCard(room: room),
        ),
      if (sclient.calendarEvents.isEmpty) Text("No event found")
    ]);
  }
}
