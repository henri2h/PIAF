import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/partials/calendar_event/date_card.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';

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
          final calendarEvent = room.getEventAttendanceEvent();
          return MaterialButton(
              onPressed: () async {
                if (room.membership == Membership.invite) await room.join();
                await context.navigateTo(CalendarEventRoute(room: room));
              },
              color: Theme.of(context).cardColor,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  children: [
                    MatrixImageAvatar(
                      client: room.client,
                      url: room.avatar,
                      width: 2000,
                      shape: MatrixImageAvatarShape.none,
                      borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          topLeft: Radius.circular(8)),
                      height: 180,
                      defaultText: room.displayname,
                      thumnailOnly:
                          false, // we don't use thumnail as this picture is from weird dimmension and preview generation don't work well
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    Row(
                      children: [
                        Expanded(child: EventCreator(room: room)),
                        if (room.membership == Membership.join)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.people, size: 18),
                                Padding(
                                  padding: const EdgeInsets.only(left: 4.0),
                                  child: Text(
                                    "${room.summary.mJoinedMemberCount}",
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                if (calendarEvent?.place != null)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Icon(
                                      Icons.place,
                                      size: 18,
                                    ),
                                  ),
                                if (calendarEvent?.place != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: Text(calendarEvent!.place?.trim() ??
                                        ',  style: const TextStyle(fontSize: 13),'),
                                  )
                              ],
                            ),
                          ),
                        if (room.membership == Membership.invite)
                          Card(
                              color: Theme.of(context).colorScheme.primary,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text("Invited",
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary)),
                              )),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (calendarEvent?.start != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: DateCard(calendarEvent: calendarEvent!),
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
                                    maxLines: 1,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                if (room.membership == Membership.invite)
                                  const ListTile(
                                      title: Text(
                                          "You've been invited to this event"),
                                      subtitle:
                                          Text("Click to join and see it")),
                                if (room.topic.isNotEmpty)
                                  Text(
                                    room.topic,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ));
        });
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
