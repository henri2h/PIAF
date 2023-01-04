import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';

import 'package:minestrix_chat/utils/matrix_widget.dart';
import '../../minestrix_room_tile.dart';
import '../minesTrix/MinesTrixTitle.dart';

class SuggestionList extends StatelessWidget {
  const SuggestionList({Key? key, required this.shouldPop}) : super(key: key);

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
          MinestrixRoomTileNavigator(room: r, shouldPop: shouldPop),
        const H2Title("Groups"),
        for (Room r in client.sgroups)
          MinestrixRoomTileNavigator(room: r, shouldPop: shouldPop),
      ]),
    );
  }
}
