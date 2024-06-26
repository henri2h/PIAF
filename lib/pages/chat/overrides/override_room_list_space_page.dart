import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:piaf/pages/chat/chat_lib/chat_page_items/chat_page_room.dart';

@RoutePage()
class OverrideRoomListSpacePage extends StatelessWidget {
  const OverrideRoomListSpacePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const ChatPageRoom();
  }
}
