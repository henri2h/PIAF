import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/pages/chat/chat_lib/chat_page_items/provider/chat_page_state.dart';
import 'package:provider/provider.dart';

@RoutePage()
class ChatPageProvider extends StatelessWidget {
  const ChatPageProvider(
      {super.key,
      required this.child,
      required this.client,
      required this.onRoomSelection,
      required this.onLongPressedSpace,
      required this.onSpaceSelection,
      this.selectedSpace =
          "Explore" /*TODO: restore CustomSpacesTypes.explore. This was removed as the build runner was not importing spaceg_list.dart*/});

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
