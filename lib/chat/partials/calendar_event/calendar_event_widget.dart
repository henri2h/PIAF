import 'package:flutter/material.dart';
import 'package:minestrix/chat/utils/extensions/minestrix/calendar_extension.dart';
import 'package:minestrix/chat/utils/poll/poll.dart';

import 'calendar_attendance_button.dart';

/// A class to let the user indicate if he will come or not

class CalendarEventWidget extends StatefulWidget {
  final Poll p;
  const CalendarEventWidget({super.key, required this.p});

  @override
  CalendarEventWidgetState createState() => CalendarEventWidgetState();
}

class CalendarEventWidgetState extends State<CalendarEventWidget> {
  Future<void> check(String? value) async {
    await widget.p.answer(value);
  }

  @override
  Widget build(BuildContext context) {
    Map<String, int> resp = widget.p.responsesMap;
    List<String> data = widget.p.userResponse?.answers ?? [];
    String userResponse = "";
    if (data.isNotEmpty) {
      userResponse = data.first;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CalendarAttendanceCardButton(
            title: "Je viens",
            icon: Icons.check,
            value: CalendarAttendanceResponses.going,
            userResponse: userResponse,
            resp: resp,
            check: check),
        CalendarAttendanceCardButton(
            title: "Intéressé",
            icon: Icons.star_border,
            value: CalendarAttendanceResponses.interested,
            userResponse: userResponse,
            resp: resp,
            check: check),
        CalendarAttendanceCardButton(
            title: "Nop",
            icon: Icons.do_not_disturb,
            value: CalendarAttendanceResponses.declined,
            userResponse: userResponse,
            resp: resp,
            check: check)
      ],
    );
  }
}
