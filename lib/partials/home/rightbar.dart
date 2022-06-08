import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/utils/social/calendar_events/calendar_events_extension.dart';

import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/partials/feed/minestrixProfileNotCreated.dart';
import 'package:minestrix/partials/minestrixRoomTile.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../../utils/settings.dart';
import '../calendar_events/calendar_events_card.dart';

class RightBar extends StatelessWidget {
  const RightBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                    List<Room> sfriends = client.sfriends.toList();

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                              itemCount: sgroups.length + sfriends.length + 2,
                              itemBuilder: (BuildContext context, int i) {
                                if (i == 0)
                                  return rightbarHeader(
                                      header: "Following",
                                      noItemText: "Following no one",
                                      hasItems: sfriends.isEmpty);

                                if (i == sfriends.length + 1)
                                  return rightbarHeader(
                                      header: "Groups",
                                      noItemText: "No groups found",
                                      hasItems: sgroups.isEmpty);

                                if (i <= sfriends.length) {
                                  return Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: MinestrixRoomTileNavigator(
                                        room: sfriends[i - 1]),
                                  );
                                } else {
                                  return Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: MinestrixRoomTileNavigator(
                                        room: sgroups[i - 2 - sfriends.length]),
                                  );
                                }
                              }),
                        ),
                        if (Settings().calendarEventSupport)
                          Expanded(
                            child: ListView(
                              children: [
                                MaterialButton(
                                  child: H2Title("Events"),
                                  onPressed: () {
                                    context
                                        .navigateTo(CalendarEventListRoute());
                                  },
                                ),
                                for (Room room in (client.calendarEvents
                                      ..sort((Room a, Room b) => b.lastEvent
                                                      ?.originServerTs !=
                                                  null &&
                                              a.lastEvent?.originServerTs !=
                                                  null
                                          ? b.lastEvent!.originServerTs
                                              .compareTo(
                                                  a.lastEvent!.originServerTs)
                                          : 0))
                                    .take(3))
                                  CalendarEventCard(room: room)
                              ],
                            ),
                          ),
                        if (client.userRoomCreated != true &&
                            client.prevBatch != null)
                          MinestrixProfileNotCreated(),
                      ],
                    );
                  });
            }));
  }
}

class rightbarHeader extends StatelessWidget {
  final String header;
  final String noItemText;
  final bool hasItems;
  const rightbarHeader(
      {Key? key,
      required this.header,
      required this.noItemText,
      required this.hasItems})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(header, style: TextStyle(fontSize: 22, letterSpacing: 1.1)),
          if (hasItems)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(Icons.no_accounts),
                  SizedBox(width: 6),
                  Text(noItemText),
                ],
              ),
            )
        ],
      ),
    );
  }
}
