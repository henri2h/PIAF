import 'package:flutter/material.dart';

import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/components/fake_text_field.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';

import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrix_widget.dart';

class PostWriterModal extends StatelessWidget {
  PostWriterModal({Key? key, required this.room}) : super(key: key);
  final Room? room;
  @override
  Widget build(BuildContext context) {
    Client client = Matrix.of(context).client;
    return room != null
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            child: Row(
              children: [
                MatrixImageAvatar(
                    client: client,
                    url: room?.creator?.avatarUrl,
                    height: 48,
                    width: 48,
                    defaultText: room?.creator?.displayName ?? client.userID,
                    backgroundColor: Theme.of(context).primaryColor,
                    thumnail: true),
                SizedBox(width: 20),
                Expanded(
                    child: FakeTextField(
                  onPressed: () {
                    if (room != null)
                      context.pushRoute(PostEditorRoute(room: room));
                  },
                  icon: Icons.edit,
                  text: "Write a post on " + (room?.name ?? ""),
                )),
              ],
            ),
          )
        : Container();
  }
}
