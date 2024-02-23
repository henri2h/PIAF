import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../../matrix/matrix_image_avatar.dart';
import 'matrix_chats_search.dart';

class MatrixChatsRoomSearchItem extends StatelessWidget {
  const MatrixChatsRoomSearchItem(
      {super.key, required this.search, required this.client});

  final SearchItem search;
  final Client client;

  @override
  Widget build(BuildContext context) {
    return ListTile(
        onTap: () {
          if (search.isProfile) {
            Navigator.pop(context, search.profile!.userId);
          } else {
            Navigator.pop(context, search.room!.id);
          }
        },
        leading: MatrixImageAvatar(
            url: search.avatar,
            client: client,
            height: MinestrixAvatarSizeConstants.small,
            width: MinestrixAvatarSizeConstants.small,
            shape: search.isSpace
                ? MatrixImageAvatarShape.rounded
                : MatrixImageAvatarShape.circle,
            backgroundColor: Theme.of(context).colorScheme.primary,
            defaultText: search.displayname),
        title: Text(search.displayname, maxLines: 1),
        subtitle: search.secondText.isNotEmpty
            ? Text(search.secondText,
                style: Theme.of(context).textTheme.bodySmall, maxLines: 1)
            : null);
  }
}
