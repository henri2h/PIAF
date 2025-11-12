import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../../../utils/extensions/minestrix/calendar_extension.dart';
import 'calendar_attendance_button.dart';

/// A class to let the user indicate if he will come or not

class CalendarEventWidget extends StatefulWidget {
  final Event poll;
  final Timeline timeline;
  const CalendarEventWidget(
      {super.key, required this.poll, required this.timeline});

  @override
  CalendarEventWidgetState createState() => CalendarEventWidgetState();
}

class CalendarEventWidgetState extends State<CalendarEventWidget> {
  late PollEventContent content;

  @override
  void initState() {
    content = widget.poll.parsedPollEventContent;
    super.initState();
  }

  Future<void> check(String? value) async {
    // TODO: add logic
  }

  @override
  Widget build(BuildContext context) {
    var room = widget.timeline.room;
    var responses = widget.poll.getPollResponses(widget.timeline);

    Map<String, int> resp = {};
    List<String> data = [];

    String userResponse = "";
    if (data.isNotEmpty) {
      userResponse = data.first;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CalendarAttendanceCardButton(
            title: "Coming",
            icon: Icons.check,
            value: CalendarAttendanceResponses.going,
            userResponse: userResponse,
            resp: resp,
            check: check),
        CalendarAttendanceCardButton(
            title: "Maybe",
            icon: Icons.star_border,
            value: CalendarAttendanceResponses.interested,
            userResponse: userResponse,
            resp: resp,
            check: check),
        CalendarAttendanceCardButton(
            title: "No",
            icon: Icons.do_not_disturb,
            value: CalendarAttendanceResponses.declined,
            userResponse: userResponse,
            resp: resp,
            check: check)
      ],
    );
  }
}
