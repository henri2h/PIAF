import 'package:flutter/material.dart';
import 'package:minestrix/partials/minestrixRoomTile.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';

class QuickLinksBar extends StatefulWidget {
  @override
  _QuickLinksBarState createState() => _QuickLinksBarState();
}

class _QuickLinksBarState extends State<QuickLinksBar>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final MinestrixClient sclient = Matrix.of(context).sclient!;

    List<MinestrixRoom> srooms = sclient.sgroups.values.toList();
    return StreamBuilder(
        stream: sclient.onSync.stream,
        builder: (context, _) => ListView.builder(
            itemCount: srooms.length,
            itemBuilder: (BuildContext context, int i) => Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: MinestrixRoomTile(sroom: srooms[i]),
                )));
  }
}
