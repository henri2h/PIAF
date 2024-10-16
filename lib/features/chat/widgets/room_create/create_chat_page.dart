import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:matrix/matrix.dart';

import '../user/selector/user_selector.dart';
import '../../../../partials/dialogs/adaptative_dialogs.dart';
import '../../pages/matrix_create_group.dart';
import 'create_group_page.dart';

@RoutePage()
class CreateChatPage extends StatefulWidget {
  const CreateChatPage(
      {super.key, required this.onRoomSelected, required this.client});

  final Client client;
  final Function(String?) onRoomSelected;

  @override
  State<CreateChatPage> createState() => _CreateChatPageState();
}

class _CreateChatPageState extends State<CreateChatPage> {
  void startChat(String userId) {
    widget.onRoomSelected(
        widget.client.getDirectChatFromUserId(userId) ?? userId);
    Navigator.of(context).pop();
  }

  final controller = UserSelectorController();

  void advancedChatOption() {
    Navigator.of(context).pop();
    AdaptativeDialogs.show(
        context: context,
        title: "Create group",
        builder: (_) => MatrixCreateGroup(
            client: widget.client, onGroupCreated: widget.onRoomSelected));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create chat"),
      ),
      body: Column(
        children: [
          Expanded(
            child: UserSelector(
                client: widget.client,
                multipleUserSelectionEnabled: false,
                onUserSelected: startChat,
                appBarBuilder: (bool isSearching) => Column(children: [
                      if (!isSearching)
                        ListTile(
                            title: const Text("New group"),
                            leading: const CircleAvatar(
                                child: Icon(Icons.group_add)),
                            onTap: () async {
                              await Navigator.of(context)
                                  .push(MaterialPageRoute(
                                      builder: (context) => CreateGroupPage(
                                            client: widget.client,
                                            onRoomSelected:
                                                widget.onRoomSelected,
                                          )));
                            }),
                      if (!isSearching)
                        ListTile(
                            title: const Text("Advanced option"),
                            subtitle: const Text(
                                "Configure E2E or create public group"),
                            leading:
                                const CircleAvatar(child: Icon(Icons.settings)),
                            onTap: advancedChatOption)
                    ]),
                state: controller),
          ),
        ],
      ),
    );
  }
}
