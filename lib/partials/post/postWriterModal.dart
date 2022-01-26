import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';

class PostWriterModal extends StatelessWidget {
  PostWriterModal({Key? key, required this.sroom}) : super(key: key);
  final MinestrixRoom? sroom;
  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;
    return Card(
        child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15),
      child: Row(
        children: [
          MatrixUserImage(
              client: sclient,
              url: sclient.userRoom!.user.avatarUrl,
              height: 48,
              width: 48,
              defaultText: sclient.userRoom!.user.displayName,
              backgroundColor: Theme.of(context).primaryColor,
              thumnail: true),
          SizedBox(width: 20),
          Expanded(
              child: TextField(
                  minLines: 1,
                  maxLines: 1,
                  readOnly: true,
                  showCursor: false,
                  onTap: () {
                    context.pushRoute(PostEditorRoute(sroom: sroom));
                  },
                  cursorColor: Colors.grey,
                  decoration: InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(
                        Radius.circular(15),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(
                        Radius.circular(15),
                      ),
                    ),
                    prefixIcon: Icon(Icons.edit, color: Colors.grey),
                    filled: true,
                    hintStyle: TextStyle(color: Colors.grey),
                    labelText: "Write a post on " + sroom!.name,
                    hintText: "Write a post on " + sroom!.name,
                    labelStyle: TextStyle(color: Colors.grey),
                  ))),
        ],
      ),
    ));
  }
}
