import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/utils/extensions/datetime.dart';

import '../../../components/shimmer_widget.dart';
import '../../../matrix/matrix_image_avatar.dart';
import '../../../matrix/matrix_room_avatar.dart';
import '../../../matrix/matrix_user_avatar.dart';
import '../../matrix_notification_count_dot.dart';

class RoomListItem extends StatelessWidget {
  const RoomListItem({
    Key? key,
    required this.room,
    required this.client,
    required this.onSelection,
    required this.selected,
  }) : super(key: key);

  final Room room;
  final bool selected;
  final Client client;
  final void Function(String) onSelection;

  @override
  Widget build(BuildContext context) {
    final bool isUnread = room.isUnreadOrInvited;
    final bool isUnreadOrNewMessage = isUnread || room.hasNewMessages;
    final color = isUnreadOrNewMessage
        ? Theme.of(context).colorScheme.onSurface
        : Colors.grey.withAlpha(180);
    final lastEvent = room.lastEvent;
    final directChatMatrixID = room.directChatMatrixID;

    return MaterialButton(
      onPressed: () {
        onSelection(room.id);
      },
      color: selected ? Theme.of(context).highlightColor : null,
      minWidth: 0,
      padding: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 60,
            color: selected ? Theme.of(context).colorScheme.primary : null,
          ),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 8, right: 12, top: 2, bottom: 2),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                focusColor: Colors.grey,
                hoverColor: Colors.grey,
                enableFeedback: true,
                leading: directChatMatrixID == null
                    ? RoomAvatar(room: room, client: client)
                    : MatrixUserAvatar(
                        avatarUrl: room.avatar,
                        userId: directChatMatrixID,
                        name: room.displayname,
                        client: client,
                        height: MinestrixAvatarSizeConstants.avatar,
                        width: MinestrixAvatarSizeConstants.avatar,
                      ),
                title: Text(room.displayname,
                    maxLines: 1,
                    style: TextStyle(
                        fontWeight: isUnreadOrNewMessage
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14)),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                        lastEvent?.originServerTs != null
                            ? lastEvent!.originServerTs.timeSinceAWeekOrDuration
                            : "Invalid time",
                        style: TextStyle(
                          fontSize: 14,
                          color: color,
                          fontWeight: isUnreadOrNewMessage
                              ? FontWeight.bold
                              : FontWeight.w500,
                        )),
                    if (isUnread) NotificationCountDot(room: room),
                    if (!isUnread && room.hasNewMessages)
                      NotificationCountDot(
                        room: room,
                        unreadMessage: true,
                      )
                  ],
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
                                      room.lastEvent?.senderId ==
                                          room.client.userID) ??
                              '',
                          maxLines: 2,
                          style: TextStyle(color: color, fontSize: 13.2)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MatrixRoomsListTileShimmer extends StatelessWidget {
  const MatrixRoomsListTileShimmer({
    Key? key,
  }) : super(key: key);

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
