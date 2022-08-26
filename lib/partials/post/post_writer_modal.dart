import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/partials/components/fake_text_field.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/partials/feed/posts/matrix_post_editor.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

class PostWriterModal extends StatelessWidget {
  PostWriterModal({Key? key, this.room}) : super(key: key);
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
                    backgroundColor: Theme.of(context).primaryColor);
              }),
          SizedBox(width: 20),
          Expanded(
              child: FakeTextField(
            onPressed: () {
              AdaptativeDialogs.show(
                  context: context,
                  title: "Create post",
                  builder: (BuildContext) => PostEditorPage(
                      room: room != null ? [room!] : client.minestrixUserRoom));
            },
            icon: Icons.edit,
            text: "Write a post on " + (room?.name ?? "your timeline"),
          )),
        ],
      ),
    );
  }
}
