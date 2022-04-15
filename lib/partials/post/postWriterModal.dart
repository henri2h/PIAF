import 'package:flutter/material.dart';

import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:minestrix_chat/partials/components/fake_text_field.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';

import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';

class PostWriterModal extends StatelessWidget {
  PostWriterModal({Key? key, required this.sroom}) : super(key: key);
  final MinestrixRoom? sroom;
  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;
    return sroom != null
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            child: Row(
              children: [
                MatrixImageAvatar(
                    client: sclient,
                    url: sclient.userRoom?.user?.avatarUrl,
                    height: 48,
                    width: 48,
                    defaultText:
                        sclient.userRoom?.user?.displayName ?? sclient.userID,
                    backgroundColor: Theme.of(context).primaryColor,
                    thumnail: true),
                SizedBox(width: 20),
                Expanded(
                    child: FakeTextField(
                  onPressed: () {
                    if (sroom != null)
                      context.pushRoute(PostEditorRoute(room: sroom!.room));
                  },
                  icon: Icons.edit,
                  text: "Write a post on " + (sroom?.name ?? ""),
                )),
              ],
            ),
          )
        : Container();
  }
}
