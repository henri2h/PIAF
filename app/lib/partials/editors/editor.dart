
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../feed/topic_list_tile.dart';

class EditorRoomTopic extends StatelessWidget {
  const EditorRoomTopic({
    super.key,
    required this.room,
  });

  final Room room;

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: const Text("Room topic"),
        subtitle: TopicBody(room: room),
        leading: const Icon(Icons.topic),
        trailing: room.canSendDefaultStates ? const Icon(Icons.edit) : null,
        onTap: !room.canSendDefaultStates
            ? null
            : () async {
                List<String>? results = await showTextInputDialog(
                  context: context,
                  textFields: [
                    DialogTextField(
                        hintText: "Set event topic", initialText: room.topic)
                  ],
                  title: "Set room topic",
                );
                if (results?.isNotEmpty == true) {
                  await room.setDescription(results![0]);
                }
              });
  }
}

class EditorRoomName extends StatelessWidget {
  const EditorRoomName({
    super.key,
    required this.room,
  });

  final Room room;

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: const Text("Room name"),
        subtitle: Text(room.name),
        leading: const Icon(Icons.title),
        trailing: room.canSendDefaultStates ? const Icon(Icons.edit) : null,
        onTap: !room.canSendDefaultStates
            ? null
            : () async {
                List<String>? results = await showTextInputDialog(
                  context: context,
                  textFields: [
                    DialogTextField(
                        hintText: "Set room name", initialText: room.name)
                  ],
                  title: "Set room name",
                );
                if (results?.isNotEmpty == true) {
                  await room.setName(results![0]);
                }
              });
  }
}
