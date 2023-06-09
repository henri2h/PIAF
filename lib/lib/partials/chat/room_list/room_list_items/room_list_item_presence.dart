import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../matrix/matrix_image_avatar.dart';
import '../../../matrix/matrix_user_item.dart';

class RoomListItemPresence extends StatelessWidget {
  const RoomListItemPresence({
    Key? key,
    required this.client,
    required this.presence,
    this.onTap,
  }) : super(key: key);

  final Client client;
  final CachedPresence presence;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Profile>(
        future: client.getProfileFromUserId(presence.userid),
        builder: (context, snap) {
          final user = snap.data;
          return MaterialButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minWidth: 0,
              padding: EdgeInsets.zero,
              onPressed: onTap,
              child: MatrixUserItem(
                  avatarUrl: user?.avatarUrl,
                  client: client,
                  name: user?.displayName,
                  userId: presence.userid,
                  avatarHeight: MinestrixAvatarSizeConstants.avatar,
                  avatarWidth: MinestrixAvatarSizeConstants.avatar,
                  subtitle: presence.lastActiveTimestamp != null
                      ? Text(timeago.format(presence.lastActiveTimestamp!))
                      : null));
        });
  }
}
