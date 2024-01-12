library minestrix_chat;

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/chat/pages/chat_page_items/chat_page_room.dart';

import 'chat_page_items/provider/chat_page_provider.dart';
import 'chat_page_items/chat_page_room_list.dart';
import 'chat_page_items/chat_page_spaces_list.dart';

/// An example implementation of the room list widget embeding
class ChatPage extends StatefulWidget {
  /// Display the rooms for the logged user.
  /// [enableStories] allow enabling the story view.
  /// [onSelection] allows overriding that happens when the user click on a chat. Mobile view only.
  /// [allowPop] allow the page to call Navigation.pop()
  const ChatPage(
      {super.key,
      required this.client,
      this.enableStories = false,
      this.onSelection});

  final Client client;
  final bool enableStories;

  final void Function(String?)? onSelection;

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
  final scrollControllerSpaces = ScrollController();
  final scrollControllerRooms = ScrollController();
  final scrollControllerDrawer = ScrollController();

  @override
  Widget build(BuildContext context) {
    return ChatPageProvider(
        client: widget.client,
        onRoomSelection: widget.onSelection,
        onSpaceSelection: (_) {}, // TODO
        onLongPressedSpace: (_) {}, // TODO
        child: Builder(builder: (context) {
          final controller = ChatPageProvider.of(context);

          return Scaffold(
            body: LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return Row(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Card(
                          child: ChatPageRoomList(
                              scrollController: scrollControllerRooms)),
                    ),
                    if (controller.selectedRoomID != null)
                      const Expanded(flex: 2, child: ChatPageRoom()),
                    if (controller.selectedRoomID == null)
                      const Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(child: Icon(Icons.chat_outlined, size: 180)),
                          ],
                        ),
                      )
                  ],
                );
              } else {
                if (controller.selectedRoomID != null) {
                  return const ChatPageRoom();
                } else {
                  return ChatPageRoomList(
                      mobile: true, scrollController: scrollControllerRooms);
                }
              }
            }),
            drawer: Drawer(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
                child: ChatPageSpaceList(
                    mobile: true, scrollController: scrollControllerDrawer),
              ),
            ),
          );
        }));
  }
}
