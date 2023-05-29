import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:minestrix_chat/view/room_list/room_list_room.dart';

@RoutePage()
class OverrideRoomListRoomPage extends StatelessWidget {
  const OverrideRoomListRoomPage(
      {Key? key, this.displaySettingsOnDesktop = false})
      : super(key: key);

  final bool displaySettingsOnDesktop;
  @override
  Widget build(BuildContext context) {
    return RoomListRoom(
      displaySettingsOnDesktop: displaySettingsOnDesktop,
    );
  }
}
