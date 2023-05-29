import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/partials/chat/spaces_list/spaces_list.dart';

import 'matrix_space_icon_button.dart';
import 'tree_space_item.dart';

class SpacesListView extends StatelessWidget {
  final MatrixSpacesList controller;
  final List<String> rootSpaces;
  const SpacesListView(
      {Key? key, required this.controller, required this.rootSpaces})
      : super(key: key);

  static const itemFirsts = [
    CustomSpacesTypes.home,
    CustomSpacesTypes.favorites,
    CustomSpacesTypes.unread,
    CustomSpacesTypes.active,
    CustomSpacesTypes.dm,
    CustomSpacesTypes.lowPriority
  ];

  int getIndex(String? element) {
    if (element == null) return 0;

    var result = itemFirsts.indexOf(element);
    if (result != -1) return result;
    return 0;
  }

  void select(int index) {
    if (index < itemFirsts.length) {
      controller.onSpaceSelected(itemFirsts[index]);
    }
  }

  void addSpace() {}

  @override
  Widget build(BuildContext context) {
    final spaceListExpanded = controller.spaceListExpanded;
    final client = controller.client;

    final spaces = client.rooms.where((Room r) => rootSpaces.contains(r.id));

    return NavigationRail(
      extended: true,
      destinations: [
        const NavigationRailDestination(
            icon: Icon(Icons.home), label: Text("home")),
        const NavigationRailDestination(
            icon: Icon(Icons.favorite), label: Text("Favorites")),
        NavigationRailDestination(
            icon: StreamBuilder(
                stream: client.onSync.stream,
                builder: (context, _) {
                  final count = client.chatNotificationsCount;
                  if (count == 0) {
                    return const Icon(Icons.notifications);
                  } else {
                    return Badge.count(
                        count: count,
                        child: const Icon(Icons.notifications_active));
                  }
                }),
            label: const Text("Unread")),
        const NavigationRailDestination(
            icon: Icon(Icons.person), label: Text("Active")),
        const NavigationRailDestination(
            icon: Icon(Icons.people), label: Text("Direct message")),
        const NavigationRailDestination(
            icon: Icon(Icons.notifications_off), label: Text("Low priority"))
      ],
      onDestinationSelected: select,
      selectedIndex: getIndex(controller.selectedSpace),
      trailing: Expanded(
        child: ListView(children: [
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
        ]),
      ),
    );
  }
}
