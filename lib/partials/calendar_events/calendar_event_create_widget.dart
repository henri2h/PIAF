import 'package:flutter/material.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/style/constants.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

class CalendarEventCreateWidget extends StatefulWidget {
  const CalendarEventCreateWidget({Key? key}) : super(key: key);

  @override
  CalendarEventCreateWidgetState createState() =>
      CalendarEventCreateWidgetState();

  static Future<void> show(BuildContext context) async {
    await AdaptativeDialogs.show(
        title: "Create event",
        context: context,
        builder: (context) => const CalendarEventCreateWidget());
  }
}

class CalendarEventCreateWidgetState extends State<CalendarEventCreateWidget> {
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
            child: const Text("Create"),
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
