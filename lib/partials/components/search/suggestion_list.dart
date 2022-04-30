import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';

import '../../../utils/matrix_widget.dart';
import '../../minestrixRoomTile.dart';
import '../minesTrix/MinesTrixTitle.dart';

class SuggestionList extends StatelessWidget {
  const SuggestionList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Client? client = Matrix.of(context).client;
    return StreamBuilder(
      stream: client.onSync.stream,
      builder: (context, _) =>
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        H2Title("Contacts"),
        for (Room r in client.sfriends) MinestrixRoomTile(room: r),
        H2Title("Groups"),
        for (Room r in client.sgroups) MinestrixRoomTile(room: r),
      ]),
    );
  }
}
