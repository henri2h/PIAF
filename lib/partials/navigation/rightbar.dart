import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/room_feed_tile_navigator.dart';
import 'package:piaf/router.gr.dart';
import 'package:piaf/utils/minestrix/minestrix_client_extension.dart';
import 'package:piaf/partials/minestrix_chat.dart';
import 'package:piaf/partials/utils/matrix_widget.dart';

import '../calendar_events/calendar_event_card.dart';
import '../components/minestrix/minestrix_title.dart';

class RightBar extends StatelessWidget {
  const RightBar({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: Matrix.of(context).onClientChange.stream,
        builder: (context, snapshot) {
          final Client client = Matrix.of(context).client;
          return Padding(
              padding: const EdgeInsets.all(8.0),
              child: FutureBuilder(
                  future: client.roomsLoading,
                  builder: (context, _) {
                    return StreamBuilder(
                        stream: client.onSync.stream,
                        builder: (context, _) {
                          List<Room> sgroups = client.sgroups.toList();

                          // If there is no list, better not display anything
                          if (sgroups.isEmpty) return Container();

                          return ListView(
                            children: [
                              if (sgroups.isNotEmpty)
                                Card(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const H2Title("Your groups"),
                                      for (final group in sgroups)
                                        Padding(
                                          padding: const EdgeInsets.all(2.0),
                                          child: RoomFeedTileNavigator(
                                              room: group),
                                        ),
                                    ],
                                  ),
                                ),
                              const CardPanelList(),
                            ],
                          );
                        });
                  }));
        });
  }
}

class RightbarHeader extends StatelessWidget {
  final String header;
  final String noItemText;
  final bool hasItems;
  const RightbarHeader(
      {super.key,
      required this.header,
      required this.noItemText,
      required this.hasItems});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(header,
              style: const TextStyle(fontSize: 22, letterSpacing: 1.1)),
          if (hasItems)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.no_accounts),
                  const SizedBox(width: 6),
                  Text(noItemText),
                ],
              ),
            )
        ],
      ),
    );
  }
}

class CardPanelList extends StatelessWidget {
  const CardPanelList({super.key});

  Future<void> postLoad(List<Room> rooms) async {
    for (Room room in rooms) {
      await room.postLoad();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: Matrix.of(context).onClientChange.stream,
        builder: (context, snapshot) {
          final Client sclient = Matrix.of(context).client;
          final calendarEvents = sclient.calendarEvents;
          return FutureBuilder(
              future: postLoad(calendarEvents),
              builder: (context, snapshot) {
                calendarEvents.sort((a, b) {
                  final aTime = a.getEventAttendanceEvent()?.start;
                  final bTime = b.getEventAttendanceEvent()?.start;

                  if (aTime == null || bTime == null) return 0;

                  return bTime.compareTo(aTime);
                });

                final post = calendarEvents.where((Room room) {
                  final event = room.getEventAttendanceEvent();
                  if (event?.start == null) return false;
                  return event!.start!.compareTo(DateTime.now()) >= 0;
                }).toList();

                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.isNotEmpty)
                        MaterialButton(
                            onPressed: () => context
                                .pushRoute(const CalendarEventListRoute()),
                            child: const H2Title("Future events")),
                      ListView.builder(
                          itemCount: post.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, pos) {
                            final item = post[pos];
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CalendarEventCard(room: item),
                            );
                          }),
                    ]);
              });
        });
  }
}
