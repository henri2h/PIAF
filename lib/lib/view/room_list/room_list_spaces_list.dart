import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../partials/chat/spaces_list/spaces_list.dart';
import 'room_list_widget.dart';

class RoomListSpacesList extends StatelessWidget {
  const RoomListSpacesList(
      {Key? key, required this.mobile, required this.scrollController})
      : super(key: key);
  final bool mobile;
  final ScrollController scrollController;
  @override
  Widget build(BuildContext context) {
    return Consumer<RoomListState>(
        builder: (context, controller, _) => MatrixSpacesList(
              controller: scrollController,
              client: controller.client,
              mobile: mobile,
              spaceListExpanded: controller.spaceListExpanded,
              onExpandClick: controller.toggleSpaceList,
              onSpaceSelected: (String? id) {
                if (mobile) {
                  Navigator.of(context).pop();
                }

                controller.selectSpace(id);
                controller.selectRoom(null);
              },
              selectedSpace: controller.selectedSpace,
              onSpaceLongPressed: controller.onLongPressedSpace,
            ));
  }
}
