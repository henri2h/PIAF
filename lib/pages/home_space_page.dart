import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:piaf/partials/chat/room_list/room_list_items/room_list_item.dart';
import 'package:piaf/partials/minestrix_chat.dart';
import 'package:piaf/router.gr.dart';

import '../partials/utils/matrix_widget.dart';

@RoutePage()
class HomeSpacePage extends StatefulWidget {
  const HomeSpacePage({super.key});

  @override
  State<HomeSpacePage> createState() => _HomeSpacePageState();
}

class _HomeSpacePageState extends State<HomeSpacePage> {
  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;

    final spaces = client.spaces;
    return Scaffold(
        appBar: AppBar(title: Text("Spaces")),
        body: ListView(
          children: [
            for (final space in spaces)
              RoomListItem(
                room: space,
                onSelection: (_) {
                  context.pushRoute(SpaceRoute(spaceId: space.id));
                },
              )
          ],
        ));
  }
}
