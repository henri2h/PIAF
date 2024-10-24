import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/minestrix_chat.dart';

import '../../utils/spaces/space_extension.dart';
import '../../features/calendar_events/partials/date_card.dart';
import '../matrix/matrix_image_avatar.dart';

class MinestrixRoomTile extends StatelessWidget {
  /// Display a small tile describing the MinesTRIX profile or group.
  /// You can else give the [room] or the [roomWithSpace]. If you give the
  /// [roomWithSpace] make sure to give also the [client].
  const MinestrixRoomTile(
      {super.key,
      this.client,
      this.room,
      this.selected = false,
      this.onTap,
      this.roomWithSpace,
      this.enableTrailing = false})
      : assert(room != null || (client != null && roomWithSpace != null)),
        assert(!(room == null && roomWithSpace == null));

  final Client? client;
  final Room? room;
  final RoomWithSpace? roomWithSpace;
  final bool selected;
  final VoidCallback? onTap;
  final bool enableTrailing;

  RoomWithSpace get r => roomWithSpace ?? RoomWithSpace(room: room);

  @override
  Widget build(BuildContext context) {
    final c = client ?? room?.client;

    final calendarEvent = room?.getEventAttendanceEvent();
    return FutureBuilder(
        future: room?.postLoad(),
        builder: (context, snapshot) {
          return ListTile(
              onTap: onTap,
              leading: calendarEvent != null
                  ? DateCard(calendarEvent: calendarEvent)
                  : MatrixImageAvatar(
                      client: c,
                      url: r.avatar,
                      defaultText: r.displayname,
                      shape: room?.feedType == FeedRoomType.user
                          ? MatrixImageAvatarShape.circle
                          : MatrixImageAvatarShape.rounded,
                      width: 42,
                      height: 42,
                    ),
              title: Text(r.displayname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (r.topic != "")
                    Text(r.topic,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: selected
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                ],
              ),
              trailing: enableTrailing
                  ? (r.room != null && r.room?.joinRules == JoinRules.public)
                      ? const Icon(Icons.public)
                      : (r.room?.encrypted != true &&
                              r.room != null &&
                              r.room?.joinRules != JoinRules.public)
                          ? const Icon(Icons.no_encryption)
                          : null
                  : null);
        });
  }
}
