import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'provider/chat_page_state.dart';
import '../../partials/chat/spaces/list/spaces_list.dart';

class ChatPageSpaceList extends StatelessWidget {
  const ChatPageSpaceList(
      {Key? key, required this.mobile, required this.scrollController})
      : super(key: key);
  final bool mobile;
  final ScrollController scrollController;
  @override
  Widget build(BuildContext context) {
    return Consumer<ChatPageState>(
        builder: (context, pageState, _) => MatrixSpacesList(
              controller: scrollController,
              client: pageState.client,
              mobile: mobile,
              spaceListExpanded: pageState.spaceListExpanded,
              onExpandClick: pageState.toggleSpaceList,
              onSpaceSelected: (String? id) {
                if (mobile) {
                  Navigator.of(context).pop();
                }

                pageState.selectSpace(id);
                pageState.selectRoom(null);
              },
              selectedSpace: pageState.selectedSpace,
              onSpaceLongPressed: pageState.onLongPressedSpace,
            ));
  }
}
