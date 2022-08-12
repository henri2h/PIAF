import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';

import '../../router.gr.dart';

class CalendarEventCard extends StatelessWidget {
  const CalendarEventCard({
    Key? key,
    required this.room,
  }) : super(key: key);

  final Room room;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: () async {
        await context.navigateTo(CalendarEventRoute(room: room));
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Stack(
        children: [
          MatrixImageAvatar(
            client: room.client,
            url: room.avatar,
            width: 2000,
            shape: MatrixImageAvatarShape.rounded,
            height: 250,
            defaultText: room.displayname,
            thumnailOnly:
                false, // we don't use thumnail as this picture is from weird dimmension and preview generation don't work well
            backgroundColor: Colors.blue,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(room.displayname),
              if (room.topic.isNotEmpty)
                Text(
                  room.topic,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              Row(
                children: [
                  const Icon(Icons.people),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child:
                        Text("${room.summary.mJoinedMemberCount} participants"),
                  )
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}
