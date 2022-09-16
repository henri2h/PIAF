import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/calendar_events/calendar_event_create_widget.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/utils/social/calendar_events/calendar_events_extension.dart';

import '../../partials/calendar_events/calendar_event_card.dart';
import '../../partials/components/layouts/custom_header.dart';
import '../../partials/components/minesTrix/MinesTrixTitle.dart';

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

  Future<void> postLoad(List<Room> rooms) async {
    for (Room room in rooms) {
      await room.postLoad();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Client sclient = Matrix.of(context).client;
    final calendarEvents = sclient.calendarEvents;

    return FutureBuilder(
        future: postLoad(calendarEvents),
        builder: (context, snapshot) {
          calendarEvents.sort((a, b) {
            final aTime = a.getEventAttendanceEvent()?.start;
            final bTime = b.getEventAttendanceEvent()?.start;

            if (aTime == null || bTime == null) return 0;

            return bTime.compareTo(aTime);
          });

          final prev = calendarEvents.where((Room room) {
            final event = room.getEventAttendanceEvent();
            if (event?.start == null) return true;
            return event!.start!.compareTo(DateTime.now()) < 0;
          }).toList();
          final post = calendarEvents.where((Room room) {
            final event = room.getEventAttendanceEvent();
            if (event?.start == null) return false;
            return event!.start!.compareTo(DateTime.now()) >= 0;
          }).toList();

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
            if (post.isNotEmpty) const H2Title("Future events"),
            GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 500, mainAxisExtent: 380),
                itemCount: post.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, pos) {
                  final item = post[pos];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CalendarEventCard(room: item),
                  );
                }),
            if (prev.isNotEmpty) const H2Title("Previous events"),
            GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 500, mainAxisExtent: 380),
                itemCount: prev.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, pos) {
                  final item = prev[pos];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CalendarEventCard(room: item),
                  );
                }),
            if (prev.isEmpty && post.isEmpty) const Text("No event found")
          ]);
        });
  }
}
