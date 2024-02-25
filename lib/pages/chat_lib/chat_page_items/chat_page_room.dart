import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'no_room_selected.dart';
import 'provider/chat_page_state.dart';
import '../../chat/room_page.dart';

@RoutePage()
class ChatPageRoom extends StatelessWidget {
  const ChatPageRoom({super.key, this.displaySettingsOnDesktop = false});
  final bool displaySettingsOnDesktop;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<ChatPageState>(
          builder: (context, controller, _) => controller.selectedRoomID == null
              ? const NoRoomSelected()
              : RoomPage(
                  key: Key("room_${controller.selectedRoomID!}"),
                  roomId: controller.selectedRoomID!,
                  client: controller.client,
                  allowPop: true,
                  displaySettingsOnDesktop: displaySettingsOnDesktop,
                  onBack: () {
                    controller.selectRoom(null);
                    Navigator.of(context).pop();
                  },
                )),
    );
  }
}
