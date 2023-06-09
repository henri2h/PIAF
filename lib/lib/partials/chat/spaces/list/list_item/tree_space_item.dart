import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import '../../../../tree_view/tree_view.dart';
import 'matrix_space_icon_button.dart';

class TreeSpaceItem extends StatefulWidget {
  final Room room;

  final bool spaceListExpanded;
  final Function(String? id)? onSpaceSelected;
  final void Function(String? id)? onLongPressed;
  final String? selectedSpace;
  const TreeSpaceItem(
      {Key? key,
      required this.room,
      required this.spaceListExpanded,
      required this.onSpaceSelected,
      required this.onLongPressed,
      required this.selectedSpace})
      : super(key: key);

  @override
  State<TreeSpaceItem> createState() => _TreeSpaceItem();
}

class _TreeSpaceItem extends State<TreeSpaceItem> {
  @override
  Widget build(BuildContext context) {
    Room r = widget.room;
    List<Room> spaceChilds = [];

    for (var child in r.spaceChildren) {
      if (child.roomId != null && (child.via?.isNotEmpty ?? false)) {
        final room = r.client.getRoomById(child.roomId!);

        if (room?.isSpace ?? false) {
          spaceChilds.add(room!);
        }
      }
    }

    return TreeViewChild(
      parent: MatrixSpaceIconButton(
          room: r,
          name: r.displayname,
          avatarUrl: r.avatar,
          client: r.client,
          id: r.id,
          selectedSpace: widget.selectedSpace,
          onPressed: widget.onSpaceSelected,
          onLongPressed: widget.onLongPressed,
          expanded: widget.spaceListExpanded),
      children: [
        for (var space in spaceChilds)
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: TreeSpaceItem(
                room: space,
                onSpaceSelected: widget.onSpaceSelected,
                selectedSpace: widget.selectedSpace,
                onLongPressed: widget.onLongPressed,
                spaceListExpanded: widget.spaceListExpanded),
          )
      ],
    );
  }
}
