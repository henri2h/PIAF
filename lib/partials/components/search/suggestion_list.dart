import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/utils/minestrix/minestrix_client_extension.dart';

import 'package:piaf/partials/utils/matrix_widget.dart';
import '../../room_feed_tile_navigator.dart';
import '../minestrix/minestrix_title.dart';

class SuggestionList extends StatelessWidget {
  const SuggestionList({super.key, required this.shouldPop});

  final bool shouldPop;

  @override
  Widget build(BuildContext context) {
    Client? client = Matrix.of(context).client;
    return StreamBuilder(
      stream: client.onSync.stream,
      builder: (context, _) =>
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const H2Title("Contacts"),
        for (Room r in client.sfriends)
          RoomFeedTileNavigator(room: r, shouldPop: shouldPop),
        const H2Title("Groups"),
        for (Room r in client.sgroups)
          RoomFeedTileNavigator(room: r, shouldPop: shouldPop),
      ]),
    );
  }
}
