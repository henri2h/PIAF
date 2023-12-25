import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../../partials/calendar_events/calendar_event_card.dart';
import '../../partials/calendar_events/calendar_event_create_widget.dart';
import '../../partials/components/minestrix/minestrix_title.dart';

@RoutePage()
class CalendarEventListPage extends StatefulWidget {
  const CalendarEventListPage({super.key});

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

          return Scaffold(
            appBar: AppBar(
              title: const Text("Events"),
              actions: [
                FilledButton.icon(
                    onPressed: createCalendarEvent,
                    icon: const Icon(Icons.add),
                    label: const Text("Add")),
              ],
            ),
            body: ListView(children: [
              if (post.isNotEmpty) const H2Title("Future events"),
              if (post.isNotEmpty)
                GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 470, mainAxisExtent: 290),
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
              if (prev.isNotEmpty)
                GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 470, mainAxisExtent: 290),
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
            ]),
          );
        });
  }
}
