import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';

import 'provider/chat_page_state.dart';
import '../../../chat/partials/chat/room_list/room_list.dart';

@RoutePage()
class ChatPageRoomList extends StatelessWidget {
  final bool mobile;
  const ChatPageRoomList(
      {super.key,
      this.mobile = false,
      required this.scrollController,
      this.onAppBarClicked});

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
              controller: controller,
              scrollController: scrollController,
              client: client,
              sortedRooms: rooms,
              isMobile: mobile,
              onAppBarClicked: onAppBarClicked,
            );
          });
    });
  }
}
