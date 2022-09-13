import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';
import 'package:minestrix_chat/utils/social/calendar_events/calendar_events_extension.dart';
import 'package:minestrix_chat/utils/social/calendar_events/model/calendar_event_model.dart';

import '../../router.gr.dart';

class CalendarEventCard extends StatelessWidget {
  const CalendarEventCard({
    Key? key,
    required this.room,
  }) : super(key: key);

  final Room room;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: room.postLoad(),
        builder: (context, snapshot) {
          return MaterialButton(
            onPressed: () async {
              await context.navigateTo(CalendarEventRoute(room: room));
            },
            color: Theme.of(context).cardColor,
            padding: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: FutureBuilder<CalendarEvent?>(
                future: room.getEventAttendanceEvent(),
                builder: (context, snap) {
                  final calendarEvent = snap.data;
                  return Column(
                    children: [
                      MatrixImageAvatar(
                        client: room.client,
                        url: room.avatar,
                        width: 2000,
                        shape: MatrixImageAvatarShape.none,
                        borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            topLeft: Radius.circular(8)),
                        height: 150,
                        defaultText: room.displayname,
                        thumnailOnly:
                            false, // we don't use thumnail as this picture is from weird dimmension and preview generation don't work well
                        backgroundColor: Colors.blue,
                      ),
                      EventCreator(room: room),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (calendarEvent?.start != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: DateWidget(calendarEvent: calendarEvent),
                            ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(room.displayname,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 19)),
                                  if (room.topic.isNotEmpty)
                                    Text(
                                      room.topic.trim(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  Row(
                                    children: [
                                      const Icon(Icons.people),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 4.0),
                                        child: Text(
                                            "${room.summary.mJoinedMemberCount} members"),
                                      )
                                    ],
                                  ),
                                  if (calendarEvent?.place != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.place),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 4.0),
                                          child: Text(
                                              calendarEvent!.place?.trim() ??
                                                  ''),
                                        )
                                      ],
                                    )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),
          );
        });
  }
}

class DateWidget extends StatelessWidget {
  const DateWidget({
    Key? key,
    required this.calendarEvent,
  }) : super(key: key);

  final CalendarEvent? calendarEvent;

  @override
  Widget build(BuildContext context) {
    return Card(
        color: Theme.of(context).primaryColor,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(DateFormat.MMM().format(calendarEvent!.start!),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 3),
              Text(DateFormat.d().format(calendarEvent!.start!),
                  style: const TextStyle(fontSize: 22))
            ],
          ),
        ));
  }
}

class EventCreator extends StatelessWidget {
  const EventCreator({
    Key? key,
    required this.room,
  }) : super(key: key);

  final Room room;

  @override
  Widget build(BuildContext context) {
    final creator = room.creator;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          const Text("Event by"),
          const SizedBox(width: 8),
          SizedBox(
            height: 26,
            width: 26,
            child: MatrixImageAvatar(
              url: creator?.avatarUrl,
              client: room.client,
              defaultText: creator?.displayName ?? creator?.id,
              textPadding: 4,
            ),
          ),
          const SizedBox(width: 4),
          Text(creator?.calcDisplayname() ?? "",
              style: const TextStyle(fontWeight: FontWeight.bold))
        ],
      ),
    );
  }
}
