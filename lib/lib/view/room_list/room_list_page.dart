library minestrix_chat;

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/view/room_list/room_list_room.dart';

import 'room_list_builder.dart';
import 'room_list_spaces_list.dart';
import 'room_list_widget.dart';

/// An example implementation of the room list widget embeding
class RoomsListPage extends StatefulWidget {
  /// Display the rooms for the logged user.
  /// [enableStories] allow enabling the story view.
  /// [onSelection] allows overriding that happens when the user click on a chat. Mobile view only.
  /// [allowPop] allow the page to call Navigation.pop()
  const RoomsListPage(
      {Key? key,
      required this.client,
      this.enableStories = false,
      this.allowPop = true,
      this.onSelection})
      : super(key: key);

  final Client client;
  final bool enableStories;
  final bool allowPop;

  final void Function(String?)? onSelection;

  @override
  RoomsListPageState createState() => RoomsListPageState();
}

class RoomsListPageState extends State<RoomsListPage>
    with SingleTickerProviderStateMixin {
  final scrollControllerSpaces = ScrollController();
  final scrollControllerRooms = ScrollController();
  final scrollControllerDrawer = ScrollController();

  @override
  Widget build(BuildContext context) {
    return RoomList(
        client: widget.client,
        allowPop: widget.allowPop,
        onRoomSelection: widget.onSelection,
        onSpaceSelection: (_) {}, // TODO
        onLongPressedSpace: (_) {}, // TODO
        child: Builder(builder: (context) {
          final controller = RoomList.of(context);

          return Scaffold(
            body: LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return Row(
                  children: [
                    SizedBox(
                        width: controller.spaceListExpanded ? 230 : 60,
                        child: RoomListSpacesList(
                            mobile: false,
                            scrollController: scrollControllerSpaces)),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Card(
                          child: RoomListBuilder(
                              scrollController: scrollControllerRooms)),
                    ),
                    if (controller.selectedRoomID != null)
                      const Expanded(flex: 2, child: RoomListRoom()),
                    if (controller.selectedRoomID == null)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Center(child: Icon(Icons.chat_outlined, size: 180)),
                          ],
                        ),
                      )
                  ],
                );
              } else {
                if (controller.selectedRoomID != null) {
                  return const RoomListRoom();
                } else {
                  return RoomListBuilder(
                      mobile: true, scrollController: scrollControllerRooms);
                }
              }
            }),
            drawer: Drawer(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
                child: RoomListSpacesList(
                    mobile: true, scrollController: scrollControllerDrawer),
              ),
            ),
          );
        }));
  }
}
