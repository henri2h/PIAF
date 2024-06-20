import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../partials/app_title.dart';
import '../tabs/tab_chat_page.dart';
import '../../partials/chat/room_list/simple_room_list.dart';

/// This class is supposed to be displayed on the right part of
/// the chat tab. In desktop mode it should render as a
/// placeholder card. On Mobile, it should render as a list.
/// This is for responsive
@RoutePage()
class RoomListOrPlaceHolderPage extends StatelessWidget {
  const RoomListOrPlaceHolderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<TabChatPageState>(context, listen: false);

    return LayoutBuilder(builder: (context, snapshot) {
      if (state.mobile) {
        return const SimpleRoomList();
      }
      return const SafeArea(child: Card(child: Center(child: AppTitle())));
    });
  }
}
