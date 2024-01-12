import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:minestrix/pages/chat_lib/chat_page_items/chat_page_room.dart';

@RoutePage()
class OverrideRoomListRoomPage extends StatelessWidget {
  const OverrideRoomListRoomPage(
      {super.key, this.displaySettingsOnDesktop = false});

  final bool displaySettingsOnDesktop;
  @override
  Widget build(BuildContext context) {
    return ChatPageRoom(
      displaySettingsOnDesktop: displaySettingsOnDesktop,
    );
  }
}
