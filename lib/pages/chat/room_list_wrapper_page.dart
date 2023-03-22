import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/view/matrix_chat_creator.dart';
import 'package:minestrix_chat/view/room_list/room_list_builder.dart';
import 'package:minestrix_chat/view/room_list/room_list_spaces_list.dart';
import 'package:minestrix_chat/view/room_list/room_list_widget.dart';
import 'package:provider/provider.dart';

import '../../router.gr.dart';

@RoutePage()
class RoomListWrapperPage extends StatefulWidget {
  const RoomListWrapperPage({Key? key}) : super(key: key);

  @override
  State<RoomListWrapperPage> createState() => RoomListWrapperPageState();
}

class RoomListWrapperPageState extends State<RoomListWrapperPage> {
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
      child: RoomList(
        client: Matrix.of(context).client,
        allowPop: false,
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
        child: Scaffold(
            body: LayoutBuilder(builder: (context, constraints) {
              mobile = constraints.maxWidth < 800;
              return Row(
                children: [
                  if (!mobile)
                    Consumer<RoomListState>(
                        builder: (context, state, _) => SizedBox(
                            width: state.spaceListExpanded ? 280 : 60,
                            child: RoomListSpacesList(
                                mobile: false,
                                scrollController: scrollControllerSpaces))),
                  if (!mobile)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Card(
                            child: RoomListBuilder(
                                scrollController: scrollControllerRoomList,
                                onAppBarClicked: () =>
                                    context.navigateTo(const SettingsRoute())),
                          )),
                    ),
                  const Expanded(child: AutoRouter()),
                ],
              );
            }),
            floatingActionButton: FloatingActionButton(
                onPressed: () {
                  AdaptativeDialogs.show(
                      context: context,
                      title: "New message",
                      builder: (_) => MatrixChatCreator(
                          client: Matrix.of(context).client,
                          onRoomSelected: onRoomSelected));
                },
                child: const Icon(Icons.create)),
            drawer: Drawer(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                child: SafeArea(
                  child: RoomListSpacesList(
                      mobile: true, scrollController: scrollControllerDrawer),
                ))),
      ),
    );
  }
}
