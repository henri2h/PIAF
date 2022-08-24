import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/calendar_events/calendar_event_create_widget.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/utils/social/calendar_events/calendar_events_extension.dart';

import '../../partials/calendar_events/calendar_event_card.dart';
import '../../partials/components/layouts/custom_header.dart';

class CalendarEventListPage extends StatefulWidget {
  const CalendarEventListPage({Key? key}) : super(key: key);

  @override
  State<CalendarEventListPage> createState() => _CalendarEventListPageState();
}

class _CalendarEventListPageState extends State<CalendarEventListPage> {
  Future<void> createCalendarEvent() async {
    await CalendarEventCreateWidget.show(context);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final Client sclient = Matrix.of(context).client;
    final calendarEvents = sclient.calendarEvents;

    return ListView(children: [
      CustomHeader(
        title: "Calendar events",
        actionButton: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: createCalendarEvent,
          )
        ],
      ),
      GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400, mainAxisExtent: 200),
          itemCount: calendarEvents.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, pos) {
            final item = calendarEvents[pos];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: CalendarEventCard(room: item),
            );
          }),
      if (sclient.calendarEvents.isEmpty) const Text("No event found")
    ]);
  }
}
