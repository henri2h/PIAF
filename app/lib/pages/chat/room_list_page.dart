import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/pages/main_wrappers/tab_chat_page.dart';
import 'package:minestrix_chat/pages/chat_page_items/chat_page_room_list.dart';
import 'package:provider/provider.dart';

import '../../partials/minestrix_title.dart';
import '../../router.gr.dart';

@RoutePage()
class RoomListPage extends StatefulWidget {
  const RoomListPage({super.key, this.isMobile = false});
  final bool isMobile;
  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  final scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, _) {
      final state = Provider.of<TabChatPageState>(context, listen: false);
      if (state.mobile) {
        return ChatPageRoomList(
          mobile: true,
          scrollController: scrollController,
          onAppBarClicked: () => context.navigateTo(const SettingsRoute()),
        );
      }

      return const SafeArea(
          child: Card(child: Center(child: MinestrixTitle())));
    });
  }
}
