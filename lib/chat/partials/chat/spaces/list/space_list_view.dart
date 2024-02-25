import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/chat/partials/chat/spaces/list/spaces_list.dart';

import 'list_item/matrix_space_icon_button.dart';
import 'list_item/tree_space_item.dart';

class SpacesListView extends StatelessWidget {
  final MatrixSpacesList controller;
  final List<String> rootSpaces;
  const SpacesListView(
      {super.key, required this.controller, required this.rootSpaces});

  @override
  Widget build(BuildContext context) {
    final spaceListExpanded = controller.spaceListExpanded;
    final client = controller.client;

    final spaces = client.rooms.where((Room r) => rootSpaces.contains(r.id));

    return ListView(children: [
      ListTile(
          title: const Text('All'),
          leading: const Icon(Icons.home),
          onTap: () => controller.onSpaceSelected(CustomSpacesTypes.home)),
      ListTile(
          title: const Text('Favorites'),
          leading: const Icon(Icons.star),
          onTap: () => controller.onSpaceSelected(CustomSpacesTypes.favorites)),
      ListTile(
          title: const Text('Unreads'),
          leading: const Icon(Icons.notifications),
          onTap: () => controller.onSpaceSelected(CustomSpacesTypes.unread)),
      ListTile(
          title: const Text('Active'),
          leading: const Icon(Icons.person),
          onTap: () => controller.onSpaceSelected(CustomSpacesTypes.active)),
      ListTile(
          title: const Text('Direct message'),
          leading: const Icon(Icons.people),
          onTap: () => controller.onSpaceSelected(CustomSpacesTypes.dm)),
      ListTile(
          title: const Text('Explore'),
          leading: const Icon(Icons.explore),
          onTap: () => controller.onSpaceSelected(CustomSpacesTypes.explore)),
      ListTile(
          title: const Text('Low priority'),
          leading: const Icon(Icons.notifications_off),
          onTap: () =>
              controller.onSpaceSelected(CustomSpacesTypes.lowPriority)),
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
