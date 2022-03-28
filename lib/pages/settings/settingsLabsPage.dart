import 'package:flutter/material.dart';

import 'package:minestrix/partials/components/layouts/customHeader.dart';
import 'package:minestrix/utils/matrixWidget.dart';

class SettingsLabsPage extends StatefulWidget {
  const SettingsLabsPage({Key? key}) : super(key: key);

  @override
  State<SettingsLabsPage> createState() => _SettingsLabsPageState();
}

class _SettingsLabsPageState extends State<SettingsLabsPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        children: [
          CustomHeader("Labs"),
          SwitchListTile(
              value: Matrix.of(context).settings.calendarEventSupport,
              onChanged: (value) {
                Matrix.of(context).settings.calendarEventSupport = value;
                setState(() {});
              },
              secondary: Icon(Icons.calendar_today),
              title: Text("Enable calendar event support"),
              subtitle: Text("Allow creating calendar events."))
        ],
      ),
    );
  }
}
