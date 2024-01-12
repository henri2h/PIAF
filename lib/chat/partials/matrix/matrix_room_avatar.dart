import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/chat/minestrix_chat.dart';

import '../calendar_event/date_card.dart';
import 'matrix_image_avatar.dart';

class RoomAvatar extends StatelessWidget {
  const RoomAvatar({
    super.key,
    required this.room,
    required this.client,
    this.unconstraigned,
    this.thumnailOnly = true,
    this.shape,
    this.width,
    this.height,
  });

  final Room room;
  final Client client;
  final bool? unconstraigned;
  final MatrixImageAvatarShape? shape;
  final bool thumnailOnly;
  final double? height;
  final double? width;

  List<User> getHeroesUsers() {
    List<User> users = room
        .getParticipants()
        .where((user) => user.avatarUrl != null && user.id != client.userID)
        .take(4)
        .toList();

    if (users.length <= 1) {
      final myUser = room
          .getParticipants()
          .firstWhereOrNull((element) => element.id == client.userID);
      if (myUser != null) {
        users.add(myUser);
      }
    }

    return users;
  }

  @override
  Widget build(BuildContext context) {
    final w = width ?? MinestrixAvatarSizeConstants.avatar;
    final h = height ?? MinestrixAvatarSizeConstants.avatar;

    if (room.feedType != null) {
      final calendarEvent = room.getEventAttendanceEvent();
      if (calendarEvent != null) {
        return DateCard(calendarEvent: calendarEvent);
      }
    }
    final roomAvatarWidget = MatrixImageAvatar(
      url: room.avatar,
      fit: true,
      defaultText: room.getLocalizedDisplayname(),
      thumnailOnly: thumnailOnly,
      shape: shape ??
          (room.isSpace || room.feedType != null
              ? MatrixImageAvatarShape.rounded
              : MatrixImageAvatarShape.circle),
      height: h,
      width: w,
      client: client,
    );

    if (room.avatar?.hasEmptyPath == false) {
      return roomAvatarWidget;
    }

    return FutureBuilder(
        future: room.requestParticipants(),
        builder: (context, snap) {
          final users = getHeroesUsers();

          if (users.length <= 1) {
            return roomAvatarWidget;
          }
          return SizedBox(
            height: h,
            width: w,
            child: Stack(children: [
              Positioned(
                top: 0,
                left: 0,
                child: RoomAvatarUserItem(
                    user: users[0],
                    client: client,
                    pad: 0,
                    height: h,
                    width: w),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: RoomAvatarUserItem(
                    user: users[1], client: client, height: h, width: w),
              ),
            ]),
          );
        });
  }
}

class RoomAvatarUserItem extends StatelessWidget {
  const RoomAvatarUserItem(
      {super.key,
      required this.user,
      required this.client,
      required this.height,
      required this.width,
      this.frac = 0.7,
      this.pad = 1});

  final User user;
  final Client client;
  final double frac;
  final double pad;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height * frac,
      width: width * frac,
      child: CircleAvatar(
        backgroundColor: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: MatrixImageAvatar(
            url: user.avatarUrl,
            client: client,
            defaultText: user.displayName ?? user.id,
            height: height,
            width: width,
          ),
        ),
      ),
    );
  }
}
