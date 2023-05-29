import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../room_page.dart';
import 'room_list_widget.dart';

class RoomListRoom extends StatelessWidget {
  const RoomListRoom({Key? key, this.displaySettingsOnDesktop = false})
      : super(key: key);
  final bool displaySettingsOnDesktop;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<RoomListState>(
          builder: (context, controller, _) => controller.selectedRoomID == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.chat, size: 40),
                        SizedBox(width: 20),
                        Text("No room selected",
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w600)),
                      ],
                    )
                  ],
                )
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
