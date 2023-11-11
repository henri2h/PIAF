import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/utils/extensions/matrix/client_extension.dart';

import 'space_list_view.dart';

class CustomSpacesTypes {
  static const String home = "Chats";
  static const String lowPriority = "Low priority";
  static const String favorites = "Favorites";
  static const String unread = "Unreads";
  static const String active = "Active";
  static const String dm = "Direct message";
  static const String explore = "Explore";
}

class MatrixSpacesList extends StatelessWidget {
  const MatrixSpacesList(
      {Key? key,
      required this.client,
      required this.onExpandClick,
      required this.spaceListExpanded,
      this.selectedSpace,
      required this.onSpaceSelected,
      required this.onSpaceLongPressed,
      required this.controller,
      this.mobile = false})
      : super(key: key);

  final Client client;
  final void Function() onExpandClick;
  final bool spaceListExpanded;
  final String? selectedSpace;
  final Function(String? id) onSpaceSelected;

  final void Function(String? id)? onSpaceLongPressed;
  final ScrollController controller;

  /// whether we should only display the spaces
  final bool mobile;

  List<String> getRootSpaces() {
    List<String> spaces = client.spaces.map((e) => e.id).toList();
    for (Room space in client.spaces) {
      for (final child in space.spaceChildren) {
        spaces.remove(child.roomId);
      }
    }
    return spaces;
  }

  @override
  Widget build(BuildContext context) {
    final rootSpaces = getRootSpaces();

    return SpacesListView(controller: this, rootSpaces: rootSpaces);
  }
}
