import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/utils/matrix_widget.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';

class FriendRequestList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Client client = Matrix.of(context).client;

    if (client.minestrixInvites.length == 0) return Container();
    return StreamBuilder(
        stream: client.onEvent.stream,
        builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: H2Title("Friend requests"),
                ),
                for (Room sm in client.minestrixInvites)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          MatrixImageAvatar(client: client, url: sm.avatar),
                          SizedBox(width: 10),
                          Text(sm.name),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                              icon: Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                await sm.join();
                              }),
                          IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await sm.leave();
                              }),
                        ],
                      ),
                    ],
                  ),
              ],
            ));
  }
}
