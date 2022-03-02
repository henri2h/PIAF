import 'package:flutter/material.dart';
import 'package:minestrix/partials/components/layouts/customHeader.dart';

class CalendarEventListPage extends StatefulWidget {
  const CalendarEventListPage({Key? key}) : super(key: key);

  @override
  State<CalendarEventListPage> createState() => _CalendarEventListPageState();
}

class _CalendarEventListPageState extends State<CalendarEventListPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      CustomHeader("Events"),
    ]);
  }
}
