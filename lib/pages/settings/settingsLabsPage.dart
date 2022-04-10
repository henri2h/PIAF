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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Experimental features, use with caution!"),
          ),
          SwitchListTile(
              value: Matrix.of(context).settings.multipleFeedSupport,
              onChanged: (value) {
                Matrix.of(context).settings.multipleFeedSupport = value;
                setState(() {});
              },
              secondary: Icon(Icons.people),
              title: Text("Allow creating multiple feeds"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "Want to share post with a subset of you friends ? Then multiple feed support is the solution."),
                  InfoBadge(text: "Not ready"),
                  InfoBadge(color: Colors.blue, text: "UI")
                ],
              )),
          SwitchListTile(
              value: Matrix.of(context).settings.calendarEventSupport,
              onChanged: (value) {
                Matrix.of(context).settings.calendarEventSupport = value;
                setState(() {});
              },
              secondary: Icon(Icons.calendar_today),
              title: Text("Enable calendar event support"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Allow creating calendar events."),
                  InfoBadge(
                    text: "Read only",
                  )
                ],
              ))
        ],
      ),
    );
  }
}

class InfoBadge extends StatelessWidget {
  const InfoBadge({Key? key, required this.text, this.color: Colors.red})
      : super(key: key);

  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Text(text, style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
