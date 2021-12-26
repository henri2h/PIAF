import 'package:flutter/material.dart';
import 'package:minestrix/partials/minestrixRoomTile.dart';
import 'package:minestrix/utils/matrixWidget.dart';

class StreamContactBar extends StatefulWidget {
  @override
  _StreamContactBarState createState() => _StreamContactBarState();
}

class _StreamContactBarState extends State<StreamContactBar>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final sclient = Matrix.of(context).sclient!;
    return StreamBuilder(
        stream: sclient.onSync.stream,
        builder: (context, _) => ListView.builder(
            itemCount: sclient.sfriends.values.length,
            itemBuilder: (BuildContext context, int i) =>
                MinestrixRoomTile(sroom: sclient.sfriends.values.toList()[i])));
  }
}
