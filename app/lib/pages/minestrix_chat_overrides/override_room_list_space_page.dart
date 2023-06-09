import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:minestrix_chat/pages/chat_page_items/chat_page_room.dart';

@RoutePage()
class OverrideRoomListSpacePage extends StatelessWidget {
  const OverrideRoomListSpacePage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ChatPageRoom();
  }
}
