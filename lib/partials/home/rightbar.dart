import 'package:flutter/material.dart';
import 'package:minestrix/partials/feed/minestrixProfileNotCreated.dart';
import 'package:minestrix/partials/minestrixRoomTile.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';

class RightBar extends StatelessWidget {
  const RightBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MinestrixClient sclient = Matrix.of(context).sclient!;
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder(
            stream: sclient.onSync.stream,
            builder: (context, _) {
              List<MinestrixRoom> sgroups = sclient.sgroups.values.toList();
              List<MinestrixRoom> sfriends = sclient.sfriends.values.toList();

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                        itemCount: sgroups.length + sfriends.length + 2,
                        itemBuilder: (BuildContext context, int i) {
                          if (i == 0)
                            return Padding(
                              padding: const EdgeInsets.all(0),
                              child: Text("Following",
                                  style: TextStyle(
                                      fontSize: 22, letterSpacing: 1.1)),
                            );

                          if (i == sfriends.length + 1)
                            return Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text("Groups",
                                  style: TextStyle(
                                      fontSize: 22, letterSpacing: 1.1)),
                            );

                          if (i <= sfriends.length) {
                            return Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: MinestrixRoomTile(sroom: sfriends[i - 1]),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: MinestrixRoomTile(
                                  sroom: sgroups[i - 2 - sfriends.length]),
                            );
                          }
                        }),
                  ),
                  if (sclient.userRoomCreated != true)
                    MinestrixProfileNotCreated(),
                ],
              );
            }));
  }
}
