import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/chat/utils/extensions/datetime.dart';

import '../../../components/shimmer_widget.dart';
import '../../../matrix/matrix_image_avatar.dart';
import '../../../matrix/matrix_room_avatar.dart';
import '../../../matrix/matrix_user_avatar.dart';
import '../../matrix_notification_count_dot.dart';

class RoomListItem extends StatelessWidget {
  const RoomListItem({
    super.key,
    required this.room,
    required this.client,
    required this.onSelection,
    required this.open,
    required this.onLongPress,
    this.selected = false,
  });

  final Room room;
  final bool open;
  final Client client;
  final void Function(String) onSelection;
  final VoidCallback onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final bool isUnread = room.isUnreadOrInvited;
    final bool isUnreadOrNewMessage = isUnread || room.hasNewMessages;
    final color = isUnreadOrNewMessage
        ? Theme.of(context).colorScheme.onSurface
        : Colors.grey.withAlpha(180);
    final fontWeight = isUnreadOrNewMessage ? FontWeight.bold : null;
    final lastEvent = room.lastEvent;
    final directChatMatrixID = room.directChatMatrixID;

    return MaterialButton(
      onPressed: () {
        onSelection(room.id);
      },
      onLongPress: onLongPress,
      color: open || selected ? Theme.of(context).highlightColor : null,
      minWidth: 0,
      padding: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 12, top: 2, bottom: 2),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          selected: selected,
          leading: SizedBox(
            height: 46,
            width: 46,
            child: selected
                ? const CircleAvatar(child: Icon(Icons.check))
                : directChatMatrixID == null
                    ? RoomAvatar(room: room, client: client)
                    : MatrixUserAvatar(
                        avatarUrl: room.avatar,
                        userId: directChatMatrixID,
                        name: room.getLocalizedDisplayname(),
                        client: client,
                        height: MinestrixAvatarSizeConstants.avatar,
                        width: MinestrixAvatarSizeConstants.avatar,
                      ),
          ),
          title: Text(
            room.getLocalizedDisplayname(),
            maxLines: 1,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: fontWeight, color: color),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (room.membership == Membership.invite)
                  const Text(
                    "Invited",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                Text(
                  lastEvent?.getLocalizedBody(
                          const MatrixDefaultLocalizations(),
                          hideReply: true,
                          hideEdit: true,
                          withSenderNamePrefix: !room.isDirectChat ||
                              room.lastEvent?.senderId == room.client.userID) ??
                      '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: fontWeight, color: color),
                ),
              ],
            ),
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                  lastEvent?.originServerTs != null
                      ? lastEvent!.originServerTs.timeSinceAWeekOrDuration
                      : "Invalid time",
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: fontWeight,
                      )),
              if (isUnread) NotificationCountDot(room: room),
              if (!isUnread && room.hasNewMessages)
                NotificationCountDot(
                  room: room,
                  unreadMessage: true,
                )
            ],
          ),
        ),
      ),
    );
  }
}

class MatrixRoomsListTileShimmer extends StatelessWidget {
  const MatrixRoomsListTileShimmer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerWidget(
      child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          focusColor: Colors.grey,
          hoverColor: Colors.grey,
          enableFeedback: true,
          leading: MatrixImageAvatar(
              url: null,
              fit: true,
              backgroundColor: Theme.of(context).colorScheme.primary,
              width: 42,
              height: 42,
              client: null),
          title: Container(
            width: 40.0,
            height: 8.0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 25.0,
                height: 6.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Container(
              width: 20,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          )),
    );
  }
}
