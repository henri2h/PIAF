import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'provider/chat_page_state.dart';
import '../spaces/list/spaces_list.dart';

@RoutePage()
class ChatPageSpaceList extends StatelessWidget {
  const ChatPageSpaceList(
      {super.key,
      required this.popAfterSelection,
      required this.scrollController,
      this.onSelection});

  final bool popAfterSelection;
  final ScrollController scrollController;
  final VoidCallback? onSelection;

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatPageState>(
        builder: (context, pageState, _) => MatrixSpacesList(
              controller: scrollController,
              client: pageState.client,
              mobile: popAfterSelection,
              spaceListExpanded: pageState.spaceListExpanded,
              onExpandClick: pageState.toggleSpaceList,
              onSpaceSelected: (String? id) {
                if (popAfterSelection) {
                  Navigator.of(context).pop();
                }

                pageState.selectSpace(id);
                pageState.selectRoom(null);

                onSelection?.call();
              },
              selectedSpace: pageState.selectedSpace,
              onSpaceLongPressed: pageState.onLongPressedSpace,
            ));
  }
}
