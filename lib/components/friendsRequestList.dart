import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';

class FriendRequestList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient;

    if (sclient.sInvites.length == 0) return Container();
    return StreamBuilder(
        stream: sclient.onEvent.stream,
        builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: H2Title("Friend requests"),
                ),
                for (MinestrixRoom sm in sclient.sInvites.values)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          MatrixUserImage(
                              client: sclient, url: sm.user.avatarUrl),
                          SizedBox(width: 10),
                          Text(sm.user.displayName),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                              icon: Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                await sm.room.join();
                              }),
                          IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await sm.room.leave();
                              }),
                        ],
                      ),
                    ],
                  ),
              ],
            ));
  }
}
