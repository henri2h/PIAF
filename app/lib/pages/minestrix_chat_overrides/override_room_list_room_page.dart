import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:minestrix_chat/pages/chat_page_items/chat_page_room.dart';

@RoutePage()
class OverrideRoomListRoomPage extends StatelessWidget {
  const OverrideRoomListRoomPage(
      {Key? key, this.displaySettingsOnDesktop = false})
      : super(key: key);

  final bool displaySettingsOnDesktop;
  @override
  Widget build(BuildContext context) {
    return ChatPageRoom(
      displaySettingsOnDesktop: displaySettingsOnDesktop,
    );
  }
}
