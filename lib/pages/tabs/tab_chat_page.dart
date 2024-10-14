import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:piaf/pages/chat/chat_lib/chat_page_items/provider/chat_page_provider.dart';
import 'package:piaf/partials/chat/room_list/simple_room_list.dart';
import 'package:piaf/partials/chat/spaces/list/spaces_list.dart';
import 'package:piaf/partials/utils/extensions/matrix/room_extension.dart';
import 'package:piaf/partials/utils/matrix_widget.dart';
import 'package:provider/provider.dart';

import '../../config/matrix_types.dart';
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
      final client = Matrix.of(context).client;
      final room = client.getRoomById(id);
      if (room?.type == MatrixTypes.todo) {
        await context.pushRoute(TodoRoomRoute(room: room!));
      } else {
        await context.navigateTo(RoomRoute(
            key: Key(id), displaySettingsOnDesktop: true, roomId: id));
      }
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
            await context.navigateTo(RoomRoute(roomId: spaceId));
          } else {
            await context.navigateTo(const RoomListOrPlaceHolderRoute());
          }
        },
        onLongPressedSpace: (String? id) async {
          if (id != null) {
            await context.navigateTo(SpaceRoute(spaceId: id));
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
                const Expanded(
                    child: AutoRouter(inheritNavigatorObservers: true)),
              ],
            );
          }),
        ),
      ),
    );
  }
}
