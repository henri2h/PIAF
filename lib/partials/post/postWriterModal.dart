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
          SizedBox(width: 30),
          Expanded(
              child: MaterialButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  color: Theme.of(context).primaryColor,
                  onPressed: () {
                    context.pushRoute(PostEditorRoute(sroom: sroom));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(9.0),
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 10),
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Write a post on " + sroom!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(sroom!.room.topic,
                                maxLines: 1, overflow: TextOverflow.ellipsis)
                          ],
                        )),
                      ],
                    ),
                  )))
        ],
      ),
    ));
  }
}
