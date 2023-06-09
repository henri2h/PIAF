import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/chat/spaces/list/spaces_list.dart';

import 'list_item/matrix_space_icon_button.dart';
import 'list_item/tree_space_item.dart';

class SpacesListView extends StatelessWidget {
  final MatrixSpacesList controller;
  final List<String> rootSpaces;
  const SpacesListView(
      {Key? key, required this.controller, required this.rootSpaces})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final spaceListExpanded = controller.spaceListExpanded;
    final client = controller.client;

    final spaces = client.rooms.where((Room r) => rootSpaces.contains(r.id));

    return ListView(children: [
      if (spaces.isNotEmpty && spaceListExpanded)
        for (Room r in spaces)
          spaceListExpanded
              ? TreeSpaceItem(
                  room: r,
                  onSpaceSelected: controller.onSpaceSelected,
                  onLongPressed: controller.onSpaceLongPressed,
                  selectedSpace: controller.selectedSpace,
                  spaceListExpanded: spaceListExpanded)
              : MatrixSpaceIconButton(
                  room: r,
                  id: r.id,
                  client: r.client,
                  name: r.name,
                  onLongPressed: controller.onSpaceLongPressed,
                  selectedSpace: controller.selectedSpace,
                  onPressed: controller.onSpaceSelected,
                  expanded: spaceListExpanded),
    ]);
  }
}
