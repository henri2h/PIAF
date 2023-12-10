import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/pages/chat/room_list_page.dart';

@RoutePage()
class OverrideRoomListPage extends StatelessWidget {
  const OverrideRoomListPage({super.key, this.isMobile = false});

  final bool isMobile;
  @override
  Widget build(BuildContext context) {
    return RoomListPage(
      isMobile: isMobile,
    );
  }
}
