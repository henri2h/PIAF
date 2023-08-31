import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';

import 'provider/chat_page_state.dart';
import '../../partials/chat/room_list/room_list.dart';

class ChatPageRoomList extends StatelessWidget {
  final bool mobile;
  const ChatPageRoomList(
      {Key? key,
      this.mobile = false,
      required this.scrollController,
      this.onAppBarClicked})
      : super(key: key);

  final ScrollController scrollController;
  final VoidCallback? onAppBarClicked;

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatPageState>(builder: (context, controller, _) {
      final client = controller.client;
      return StreamBuilder<Object>(
          stream: client.onSync.stream.where((up) => up.hasRoomUpdate),
          builder: (context, snapshot) {
            final rooms = controller.getRoomList(client);

            return RoomList(
                controller: scrollController,
                selectedRoomId: controller.selectedRoomID,
                client: client,
                sortedRooms: rooms,
                displaySpaceList: controller.displaySpaceList,
                isMobile: mobile,
                selectedSpace: controller.selectedSpace,
                onAppBarClicked: onAppBarClicked,
                onSelection: (String? roomId) {
                  controller.selectRoom(roomId);
                });
          });
    });
  }
}
