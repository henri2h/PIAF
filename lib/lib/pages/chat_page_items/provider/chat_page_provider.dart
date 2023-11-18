import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/pages/chat_page_items/provider/chat_page_state.dart';
import 'package:minestrix_chat/partials/chat/spaces/list/spaces_list.dart';
import 'package:provider/provider.dart';

class ChatPageProvider extends StatelessWidget {
  const ChatPageProvider(
      {super.key,
      required this.child,
      required this.client,
      required this.onRoomSelection,
      required this.onLongPressedSpace,
      required this.onSpaceSelection,
      this.selectedSpace = CustomSpacesTypes.explore});

  final Widget child;
  final Client client;
  final void Function(String?)? onRoomSelection;
  final void Function(String)? onSpaceSelection;
  final void Function(String?) onLongPressedSpace;
  final String selectedSpace;

  /// Returns the (nearest) Client instance of your application.
  static ChatPageState of(BuildContext context) {
    return Provider.of<ChatPageState>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChatPageState(
          selectedSpace: selectedSpace,
          context: context,
          client: client,
          onLongPressedSpace: onLongPressedSpace,
          onRoomSelection: onRoomSelection,
          onSpaceSelection: onSpaceSelection),
      child: child,
    );
  }
}
