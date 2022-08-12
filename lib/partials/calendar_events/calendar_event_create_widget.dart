import 'package:flutter/material.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/style/constants.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/utils/social/calendar_events/calendar_events_extension.dart';

class CalendarEventCreateWidget extends StatefulWidget {
  CalendarEventCreateWidget({Key? key}) : super(key: key);

  @override
  _CalendarEventCreateWidgetState createState() =>
      _CalendarEventCreateWidgetState();

  static Future<void> show(BuildContext context) async {
    await AdaptativeDialogs.show(
        title: "Create event",
        context: context,
        builder: (context) => CalendarEventCreateWidget());
  }
}

class _CalendarEventCreateWidgetState extends State<CalendarEventCreateWidget> {
  final nameController = TextEditingController();
  final topicController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
              controller: nameController,
              decoration: Constants.kTextFieldInputDecoration.copyWith(
                prefixIcon: const Icon(Icons.title, color: Colors.grey),
                hintText: "Event name",
              )),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
              controller: topicController,
              minLines: 3,
              maxLines: 8,
              decoration: Constants.kTextFieldInputDecoration.copyWith(
                prefixIcon: const Icon(Icons.topic, color: Colors.grey),
                hintText: "topic",
              )),
        ),
        MaterialButton(
            child: Text("Create"),
            onPressed: () async {
              final client = Matrix.of(context).client;
              await client.createCalendarEventRoom(client,
                  name: nameController.text, topic: topicController.text);
              Navigator.of(context).pop();
            })
      ],
    );
  }
}
