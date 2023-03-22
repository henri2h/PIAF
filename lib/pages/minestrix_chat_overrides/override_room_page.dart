import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/view/room_page.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class OverrideRoomPage extends StatelessWidget {
  const OverrideRoomPage(
      {Key? key,
      required this.roomId,
      required this.client,
      this.onBack,
      this.allowPop = false,
      this.displaySettingsOnDesktop = false})
      : super(key: key);

  final String roomId;
  final Client client;
  final void Function()? onBack;
  final bool allowPop;
  final bool displaySettingsOnDesktop;

  @override
  Widget build(BuildContext context) {
    return RoomPage(
        roomId: roomId,
        client: client,
        onBack: onBack,
        displaySettingsOnDesktop: displaySettingsOnDesktop,
        allowPop: allowPop);
  }
}
