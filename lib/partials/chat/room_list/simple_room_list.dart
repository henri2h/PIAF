import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';

import 'room_list.dart';
import '../../../router.gr.dart';
import '../../../pages/chat/chat_lib/chat_page_items/provider/chat_page_state.dart';

class SimpleRoomList extends StatelessWidget {
  final bool mobile;
  const SimpleRoomList({super.key, this.mobile = false});

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    return Consumer<ChatPageState>(builder: (context, controller, _) {
      final client = controller.client;

      return FutureBuilder(
          future: client.roomsLoading,
          builder: (context, snap) {
            return StreamBuilder<SyncUpdate>(
                stream: client.onSync.stream.where((up) => up.hasRoomUpdate),
                builder: (context, snapshot) {
                  final rooms = controller.getFilteredRoomList(client);

                  return RoomList(
                    controller: controller,
                    scrollController: scrollController,
                    client: client,
                    sortedRooms: rooms,
                    isMobile: true,
                    onAppBarClicked: () =>
                        context.navigateTo(const SettingsRoute()),
                  );
                });
          });
    });
  }
}
