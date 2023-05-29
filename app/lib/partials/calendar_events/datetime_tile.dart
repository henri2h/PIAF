import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/minestrix/minestrix_title.dart';

class DateTimeTile extends StatelessWidget {
  const DateTimeTile({Key? key, required this.date, required this.text})
      : super(key: key);
  final DateTime date;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: H3Title(text),
        ),
        Row(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: ListTile(
                title: Text(DateFormat.Hm().format(date)),
                leading: const Icon(
                  Icons.schedule,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: ListTile(
                title: Text(DateFormat.MMMEd().format(date)),
                leading: const Icon(
                  Icons.calendar_today,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
