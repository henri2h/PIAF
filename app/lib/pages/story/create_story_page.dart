import 'package:flutter/material.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../../partials/calendar_events/calendar_text_field.dart';

class CreateStoryPage extends StatefulWidget {
  const CreateStoryPage({super.key});
  static Future<void> show({required BuildContext context}) async {
    await AdaptativeDialogs.show(
        context: context,
        bottomSheet: true,
        builder: (context) => const CreateStoryPage());
  }

  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  final nameController = TextEditingController();
  final topicController = TextEditingController();

  Future<void> onSubmit() async {
    final client = Matrix.of(context).client;
    await client.createStoryRoom(
        name: nameController.text, topic: topicController.text);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Create story")),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                child: ListView(children: [
                  CreateCalendarTextField(
                    text: "Event name",
                    icon: const Icon(Icons.title),
                    controller: nameController,
                  ),
                  CreateCalendarTextField(
                    text: "Story room description",
                    controller: topicController,
                    icon: const Icon(Icons.topic),
                    minLines: 3,
                    maxLines: null,
                  ),
                ]),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: FilledButton(
                        onPressed: onSubmit,
                        child: const Text("Create story room")),
                  ),
                ],
              )
            ],
          ),
        ));
  }
}
