import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/utils/minestrix/minestrix_client_extension.dart';
import 'package:piaf/chat/partials/components/fake_text_field.dart';
import 'package:piaf/chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:piaf/chat/partials/feed/posts/matrix_post_editor.dart';
import 'package:piaf/chat/partials/matrix/matrix_image_avatar.dart';
import 'package:piaf/chat/utils/matrix_widget.dart';

class PostWriterModal extends StatelessWidget {
  const PostWriterModal({super.key, this.room});
  final Room? room;
  @override
  Widget build(BuildContext context) {
    Client client = Matrix.of(context).client;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      child: Row(
        children: [
          FutureBuilder<Profile>(
              future: client.getProfileFromUserId(client.userID!),
              builder: (context, snap) {
                return MatrixImageAvatar(
                    client: client,
                    url: snap.data?.avatarUrl,
                    height: 48,
                    width: 48,
                    defaultText: snap.data?.displayName ?? client.userID,
                    backgroundColor: Theme.of(context).colorScheme.primary);
              }),
          const SizedBox(width: 20),
          Expanded(
              child: FakeTextField(
            onPressed: () {
              AdaptativeDialogs.show(
                  context: context,
                  title: "Create post",
                  builder: (BuildContext context) => PostEditorPage(
                      room: room != null ? [room!] : client.minestrixUserRoom));
            },
            icon: Icons.edit,
            text: "Write a post on ${room?.name ?? "your timeline"}",
          )),
        ],
      ),
    );
  }
}
