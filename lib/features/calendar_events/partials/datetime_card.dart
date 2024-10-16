import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'calendar_section.dart';

class DateTimeCard extends StatelessWidget {
  const DateTimeCard({super.key, required this.date, required this.setTime});

  final DateTime date;
  final void Function(DateTime) setTime;

  @override
  Widget build(BuildContext context) {
    var startTime = TimeOfDay(hour: date.hour, minute: date.minute);

    return Row(
      children: [
        Expanded(
          child: CreateCalendarSection(
            text: "Date",
            child: MaterialButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              color: Theme.of(context).colorScheme.surfaceVariant,
              onPressed: () async {
                final result = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100) // huh
                    );

                if (result != null) {
                  setTime(result.applied(startTime));
                }
              },
              child: ListTile(
                leading: const Icon(Icons.edit_calendar),
                title: Text(DateFormat.MMMEd().format(date)),
              ),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: CreateCalendarSection(
            text: "Time",
            child: MaterialButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              color: Theme.of(context).colorScheme.surfaceVariant,
              onPressed: () async {
                final result = await showTimePicker(
                    context: context, initialTime: startTime);
                if (result != null) {
                  setTime(date.applied(result));
                }
              },
              child: ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(DateFormat.Hm().format(date)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

extension DateTimeExtension on DateTime {
  DateTime applied(TimeOfDay time) {
    return DateTime(year, month, day, time.hour, time.minute);
  }
}
