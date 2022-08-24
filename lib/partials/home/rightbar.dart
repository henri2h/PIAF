import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/feed/minestrixProfileNotCreated.dart';
import 'package:minestrix/partials/minestrixRoomTile.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

class RightBar extends StatelessWidget {
  const RightBar({Key? key}) : super(key: key);

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
                          List<Room> sfriends = client.sfriends.toList();

                          return Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                    itemCount:
                                        sgroups.length + sfriends.length + 2,
                                    itemBuilder: (BuildContext context, int i) {
                                      if (i == 0) {
                                        return RightbarHeader(
                                            header: "Following",
                                            noItemText: "Following no one",
                                            hasItems: sfriends.isEmpty);
                                      }

                                      if (i == sfriends.length + 1) {
                                        return RightbarHeader(
                                            header: "Groups",
                                            noItemText: "No groups found",
                                            hasItems: sgroups.isEmpty);
                                      }

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
                                              room: sgroups[
                                                  i - 2 - sfriends.length]),
                                        );
                                      }
                                    }),
                              ),
                              if (client.userRoomCreated != true &&
                                  client.prevBatch != null)
                                const MinestrixProfileNotCreated(),
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
