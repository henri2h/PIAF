import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/chat/partials/chat/room_list/simple_room_list.dart';

import 'package:minestrix/pages/chat_lib/chat_page_items/provider/chat_page_provider.dart';
import 'package:minestrix/chat/partials/chat/spaces/list/spaces_list.dart';

import 'package:minestrix/chat/utils/matrix_widget.dart';
import 'package:provider/provider.dart';

import '../../router.gr.dart';

@RoutePage()
class TabChatPage extends StatefulWidget {
  const TabChatPage({super.key});

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
      await context.navigateTo(const RoomListOrPlaceHolderRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: this,
      child: ChatPageProvider(
        client: Matrix.of(context).client,

        // Open the explore view by default for guests
        selectedSpace: Matrix.of(context).isGuest == true
            ? CustomSpacesTypes.explore
            : CustomSpacesTypes.home,

        onRoomSelection: onRoomSelected,
        onSpaceSelection: (String spaceId) async {
          if (spaceId.startsWith("#") || spaceId.startsWith("!")) {
            await context.navigateTo(const OverrideRoomListSpaceRoute());
          } else {
            await context.navigateTo(const RoomListOrPlaceHolderRoute());
          }
        },
        onLongPressedSpace: (String? id) async {
          if (id != null) {
            await context.navigateTo(OverrideRoomSpaceRoute(
                spaceId: id, client: Matrix.of(context).client));
          }
        },

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
                        child: const Card(
                          child: SimpleRoomList(
                            mobile: false,
                          ),
                        )),
                  ),
                const Expanded(child: AutoRouter()),
              ],
            );
          }),
        ),
      ),
    );
  }
}
