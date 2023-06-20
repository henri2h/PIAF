import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import '../../matrix/matrix_image_avatar.dart';
import '../matrix_notification_count_dot.dart';
import 'matrix_chats_search.dart';

class MatrixChatsRoomSearchItem extends StatelessWidget {
  const MatrixChatsRoomSearchItem(
      {Key? key, required this.search, required this.client})
      : super(key: key);

  final SearchItem search;
  final Client client;

  @override
  Widget build(BuildContext context) {
    final unreadOrInvited = search.room?.isUnreadOrInvited == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8.0),
      child: MaterialButton(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14))),
        onPressed: () {
          if (search.isProfile) {
            Navigator.pop(context, search.profile!.userId);
          } else {
            Navigator.pop(context, search.room!.id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(children: [
            Padding(
              padding: const EdgeInsets.all(0.0),
              child: MatrixImageAvatar(
                  url: search.avatar,
                  client: client,
                  height: MinestrixAvatarSizeConstants.small,
                  width: MinestrixAvatarSizeConstants.small,
                  shape: search.isSpace
                      ? MatrixImageAvatarShape.rounded
                      : MatrixImageAvatarShape.circle,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  defaultText: search.displayname),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Wrap(
                direction: Axis.horizontal,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(search.displayname, maxLines: 1),
                      if (search.secondText.isNotEmpty)
                        Text(search.secondText,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1)
                    ],
                  ),
                ],
              ),
            ),
            if (search.room != null && unreadOrInvited)
              NotificationCountDot(room: search.room!),
            if (search.room != null &&
                !unreadOrInvited &&
                search.room?.hasNewMessages == true)
              NotificationCountDot(
                room: search.room!,
                unreadMessage: true,
              ),
          ]),
        ),
      ),
    );
  }
}
