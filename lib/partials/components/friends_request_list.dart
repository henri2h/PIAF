import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/minestrix/minestrix_title.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix/chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix/chat/utils/matrix_widget.dart';

class FriendRequestList extends StatelessWidget {
  const FriendRequestList({super.key});

  @override
  Widget build(BuildContext context) {
    Client client = Matrix.of(context).client;

    if (client.minestrixInvites.isEmpty) return Container();
    return StreamBuilder(
        stream: client.onEvent.stream,
        builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: H2Title("Friend requests"),
                ),
                for (Room sm in client.minestrixInvites)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          MatrixImageAvatar(client: client, url: sm.avatar),
                          const SizedBox(width: 10),
                          Text(sm.name),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                await sm.join();
                              }),
                          IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
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
