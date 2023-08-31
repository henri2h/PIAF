import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:minestrix_chat/pages/chat_page_items/chat_page_room_list.dart';
import 'package:minestrix_chat/pages/chat_page_items/chat_page_spaces_list.dart';

import 'package:minestrix_chat/pages/chat_page_items/provider/chat_page_provider.dart';

import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/pages/room_creator_page.dart';
import 'package:provider/provider.dart';

import '../../router.gr.dart';

@RoutePage()
class TabChatPage extends StatefulWidget {
  const TabChatPage({Key? key}) : super(key: key);

  @override
  State<TabChatPage> createState() => TabChatPageState();
}

class TabChatPageState extends State<TabChatPage> {
  final scrollControllerSpaces = ScrollController();
  final scrollControllerDrawer = ScrollController();
  final scrollControllerRoomList = ScrollController();

  bool mobile = true;
  Future<void> onRoomSelected(String? id) async {
    if (id != null) {
      await context.navigateTo(
          OverrideRoomListRoomRoute(displaySettingsOnDesktop: true));
    } else {
      await context.navigateTo(OverrideRoomListRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => this,
      child: ChatPageProvider(
        client: Matrix.of(context).client,
        onRoomSelection: onRoomSelected,
        onSpaceSelection: (String spaceId) async {
          if (spaceId.startsWith("#") || spaceId.startsWith("!")) {
            await context.navigateTo(const OverrideRoomListSpaceRoute());
          } else {
            await context.navigateTo(RoomListRoute());
          }
        },
        onLongPressedSpace: (String? id) async {
          if (id != null) {
            await context.navigateTo(OverrideRoomSpaceRoute(
                spaceId: id, client: Matrix.of(context).client));
          }
        },
        child: SafeArea(
          child: Scaffold(
              body: LayoutBuilder(builder: (context, constraints) {
                mobile = constraints.maxWidth < 800;
                return Row(
                  children: [
                    if (!mobile)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Card(
                              child: ChatPageRoomList(
                                  scrollController: scrollControllerRoomList,
                                  onAppBarClicked: () => context
                                      .navigateTo(const SettingsRoute())),
                            )),
                      ),
                    const Expanded(child: AutoRouter()),
                  ],
                );
              }),
              drawer: Drawer(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  child: SafeArea(
                    child: ChatPageSpaceList(
                        mobile: true, scrollController: scrollControllerDrawer),
                  ))),
        ),
      ),
    );
  }
}
