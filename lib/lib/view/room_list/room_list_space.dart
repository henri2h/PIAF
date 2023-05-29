import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../partials/chat/spaces_list/space_page.dart';
import 'room_list_widget.dart';

class RoomListSpace extends StatelessWidget {
  const RoomListSpace({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Consumer<RoomListState>(
        builder: (context, controller, _) =>
            !controller.selectedSpace.startsWith("!")
                ? Text("No room selected ${controller.selectedSpace}")
                : RoomSpacePage(
                    key: Key("space_${controller.selectedSpace}"),
                    spaceId: controller.selectedSpace,
                    client: controller.client,
                    onBack: () {
                      controller.selectRoom(null);
                      Navigator.of(context).pop();
                    },
                  ));
  }
}
