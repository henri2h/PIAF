import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/extensions/minestrix/model/calendar_event_model.dart';

class DateCard extends StatelessWidget {
  const DateCard({
    super.key,
    required this.calendarEvent,
  });

  final CalendarEvent calendarEvent;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          color: Theme.of(context).colorScheme.primary,
        ),
        height: 42,
        width: 42,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            children: [
              Text(DateFormat.MMM().format(calendarEvent.start!),
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onPrimary,
                  )),
              Text(DateFormat.d().format(calendarEvent.start!),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ))
            ],
          ),
        ));
  }
}
