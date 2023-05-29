import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';

import '../../partials/chat/room_list/matrix_chats_list.dart';
import 'room_list_widget.dart';

class RoomListBuilder extends StatelessWidget {
  final bool mobile;
  const RoomListBuilder(
      {Key? key,
      this.mobile = false,
      required this.scrollController,
      this.appBarColor,
      this.onAppBarClicked})
      : super(key: key);

  final ScrollController scrollController;
  final Color? appBarColor;
  final VoidCallback? onAppBarClicked;

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomListState>(builder: (context, controller, _) {
      final client = controller.client;
      return StreamBuilder<Object>(
          stream: client.onSync.stream.where((up) => up.hasRoomUpdate),
          builder: (context, snapshot) {
            final rooms = controller.getRoomList(client);

            return MatrixChatsList(
                controller: scrollController,
                selectedRoomId: controller.selectedRoomID,
                allowPop: controller.allowPop,
                client: client,
                sortedRooms: rooms,
                isMobile: mobile,
                selectedSpace: controller.selectedSpace,
                appBarColor: appBarColor,
                onAppBarClicked: onAppBarClicked,
                onSelection: (String? roomId) {
                  controller.selectRoom(roomId);
                });
          });
    });
  }
}
