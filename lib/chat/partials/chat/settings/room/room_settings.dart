import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:matrix/matrix.dart';

import 'package:piaf/chat/minestrix_chat.dart';
import 'package:pasteboard/pasteboard.dart';
import '../../../dialogs/custom_dialogs.dart';
import '../../../matrix/matrix_image_avatar.dart';

class RoomSettings extends StatefulWidget {
  final Room room;
  final VoidCallback onLeave;
  const RoomSettings({super.key, required this.room, required this.onLeave});

  @override
  State<RoomSettings> createState() => _RoomSettingsState();
}

class _RoomSettingsState extends State<RoomSettings> {
  bool uploadingFile = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: uploadingFile
              ? const Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 10),
                    Text("Uploading file")
                  ],
                )
              : Center(
                  child: Stack(
                  children: [
                    Center(
                      child: MaterialButton(
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12))),
                          padding: const EdgeInsets.all(14),
                          minWidth: 20,
                          onPressed: widget.room.canSendDefaultStates
                              ? () async {
                                  FilePickerResult? result =
                                      await FilePicker.platform.pickFiles(
                                          type: FileType.image, withData: true);

                                  if (result?.files.first.bytes == null) return;

                                  setState(() {
                                    uploadingFile = true;
                                  });

                                  await widget.room.setAvatar(MatrixFile(
                                      bytes: result!.files.first.bytes!,
                                      name: result.files.first.name));

                                  setState(() {
                                    uploadingFile = false;
                                  });
                                }
                              : null,
                          child: MatrixImageAvatar(
                            client: widget.room.client,
                            url: widget.room.avatar,
                            width: 120,
                            height: 120,
                            defaultText: widget.room.getLocalizedDisplayname(),
                          )),
                    ),
                    if (widget.room.canSendDefaultStates)
                      Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                setState(() {
                                  uploadingFile = true;
                                });

                                await widget.room.setAvatar(null);

                                setState(() {
                                  uploadingFile = false;
                                });
                              }))
                  ],
                )),
        ),
        ListTile(
            title: const Text("Room name"),
            subtitle: Text(widget.room.getLocalizedDisplayname().isEmpty &&
                    widget.room.canSendDefaultStates
                ? 'Set the room name'
                : widget.room.getLocalizedDisplayname()),
            leading: const Icon(Icons.title),
            trailing: widget.room.canSendDefaultStates
                ? const Icon(Icons.edit)
                : null,
            onTap: widget.room.canSendDefaultStates
                ? () async {
                    String? name = await CustomDialogs.showCustomTextDialog(
                        context,
                        title: "Set the room name",
                        helpText: "Room name",
                        initialText: widget.room.name);
                    if (name != null) {
                      await widget.room.setName(
                          name); // if is matrix, will also change the name
                      await widget.room.waitForRoomSync();
                      setState(() {});
                    }
                  }
                : null),
        ListTile(
            title: const Text("Topic"),
            subtitle: Text(
                widget.room.topic.isEmpty && widget.room.canSendDefaultStates
                    ? 'Set a topic'
                    : widget.room.topic),
            leading: const Icon(Icons.topic),
            trailing: widget.room.canSendDefaultStates
                ? const Icon(Icons.edit)
                : null,
            onTap: widget.room.canSendDefaultStates
                ? () async {
                    String? description =
                        await CustomDialogs.showCustomTextDialog(
                      context,
                      title: "Set the room topic",
                      helpText: "Room topic",
                      initialText: widget.room.topic,
                    );
                    if (description != null) {
                      // Edit the description

                      await widget.room.setDescription(description);
                      await widget.room.waitForRoomSync();
                      setState(() {});
                    }
                  }
                : null),
        if (widget.room.summary.mJoinedMemberCount == 2)
          SwitchListTile(
            title: const Text("Direct chat"),
            onChanged: (value) async {
              if (value) {
                final userId = widget.room
                    .getParticipants()
                    .firstWhereOrNull(
                        (user) => user.id != widget.room.client.userID)
                    ?.id;
                if (userId != null) {
                  await widget.room.addToDirectChat(userId);
                }
              } else {
                await widget.room.removeFromDirectChat();
              }
              setState(() {});
            },
            value: widget.room.isDirectChat,
          ),
        ListTile(
          title: const Text("Room ID"),
          subtitle: Text(widget.room.id),
          leading: const Icon(Icons.numbers),
          trailing: const Icon(Icons.copy),
          onTap: () {
            Pasteboard.writeText(widget.room.id);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Copied room ID in the clipbard."),
            ));
          },
        )
      ],
    );
  }
}
