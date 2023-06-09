import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../../components/fake_text_field.dart';
import '../../matrix/matrix_image_avatar.dart';
import '../search/matrix_chats_search.dart';

class ChatsSearchButton extends StatelessWidget {
  const ChatsSearchButton({
    Key? key,
    required this.client,
    required this.onSelection,
    required this.onUserTap,
  }) : super(key: key);

  final Client client;
  final Function(String p1) onSelection;
  final VoidCallback? onUserTap;

  @override
  Widget build(BuildContext context) {
    return FakeTextField(
        onPressed: () async {
          String? roomId = await MatrixChatsSearch.show(context, client);

          if (roomId != null) {
            onSelection(roomId);
          }
        },
        text: "Search",
        icon: Icons.search,
        trailing: IconButton(
          onPressed: onUserTap,
          padding: EdgeInsets.zero,
          icon: FutureBuilder(
              future: client.getProfileFromUserId(client.userID!),
              builder: (BuildContext context, AsyncSnapshot<Profile> p) {
                return p.data?.avatarUrl != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: CircleAvatar(
                          radius: 19,
                          child: MatrixImageAvatar(
                              client: client,
                              url: p.data!.avatarUrl,
                              fit: true,
                              width: 34,
                              height: 34),
                        ),
                      )
                    : const Icon(Icons.person);
              }),
        ));
  }
}
