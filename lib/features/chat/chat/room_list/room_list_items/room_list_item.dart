import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/utils/date_time_extension.dart';

import '../../../../../router.gr.dart';
import '../../../../../partials/chat_components/shimmer_widget.dart';
import '../../../../../partials/matrix/matrix_image_avatar.dart';
import '../../../../../partials/matrix/matrix_room_avatar.dart';
import '../../../../../partials/matrix/matrix_user_avatar.dart';
import '../../../../../utils/matrix_widget.dart';
import '../../../widgets/matrix_notification_count_dot.dart';

class RoomListItem extends StatelessWidget {
  const RoomListItem({
    super.key,
    required this.room,
    this.onSelection,
    this.opened = false,
    this.onLongPress,
    this.selected = false,
  });

  final Room room;
  final bool opened;

  final void Function(String)? onSelection;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;

    final bool isUnread = room.isUnreadOrInvited;
    final color = isUnread
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outline;
    final fontWeight = isUnread ? FontWeight.bold : null;
    final lastEvent = room.lastEvent;
    final directChatMatrixID = room.directChatMatrixID;

    return FutureBuilder<List<User>>(
        future: room.loadHeroUsers(),
        builder: (context, snapshot) {
          return MaterialButton(
            onPressed: () async {
              if (onSelection != null) {
                onSelection!(room.id);
              } else {
                await context
                    .pushRoute(RoomRoute(key: Key(room.id), roomId: room.id));
              }
            },
            onLongPress: onLongPress,
            color: opened || selected ? Theme.of(context).highlightColor : null,
            minWidth: 0,
            padding: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 0, right: 16, top: 8, bottom: 10),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      height: MinestrixAvatarSizeConstants.roomListAvatar,
                      width: MinestrixAvatarSizeConstants.roomListAvatar,
                      child: selected
                          ? const CircleAvatar(child: Icon(Icons.check))
                          : directChatMatrixID == null
                              ? RoomAvatar(
                                  room: room,
                                  client: client,
                                  width: MinestrixAvatarSizeConstants
                                      .roomListAvatar,
                                )
                              : MatrixUserAvatar(
                                  avatarUrl: room.avatar,
                                  userId: directChatMatrixID,
                                  name: room.getLocalizedDisplayname(),
                                  client: client,
                                  height: MinestrixAvatarSizeConstants
                                      .roomListAvatar,
                                  width: MinestrixAvatarSizeConstants
                                      .roomListAvatar,
                                ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.getLocalizedDisplayname(),
                                maxLines: 1,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        fontWeight: fontWeight,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface),
                              ),
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
                                        withSenderNamePrefix:
                                            !room.isDirectChat ||
                                                room.lastEvent?.senderId ==
                                                    room.client.userID) ??
                                    '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        fontWeight: fontWeight,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                                lastEvent?.originServerTs != null
                                    ? lastEvent!.originServerTs.simpleFormatTime
                                    : "Invalid time",
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: color,
                                      fontWeight: fontWeight,
                                    )),
                            if (isUnread) NotificationCountDot(room: room),
                            if (room.pushRuleState == PushRuleState.dontNotify)
                              const Icon(Icons.volume_mute)
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}

class RoomListItemShimmer extends StatelessWidget {
  const RoomListItemShimmer({
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
