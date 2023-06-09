import 'package:flutter/material.dart' hide Visibility;
import 'package:matrix/matrix.dart';

import '../partials/chat/user/selector/user_selector.dart';
import '../partials/dialogs/adaptative_dialogs.dart';
import 'matrix_create_group.dart';

class RoomCreatorPage extends StatefulWidget {
  const RoomCreatorPage(
      {Key? key, required this.onRoomSelected, required this.client})
      : super(key: key);

  final Client client;
  final Function(String?) onRoomSelected;

  @override
  State<RoomCreatorPage> createState() => _RoomCreatorPageState();
}

class _RoomCreatorPageState extends State<RoomCreatorPage> {
  bool createGroup = false;

  bool _creating = false;

  void _createGroup() async {
    setState(() {
      _creating = true;
    });

    final roomId = await widget.client.createGroupChat(
        enableEncryption: true,
        invite: controller.selectedUsers.toList(),
        preset: CreateRoomPreset.privateChat,
        visibility: Visibility.private);

    if (mounted) {
      setState(() {
        _creating = false;
      });
      Navigator.of(context).pop();
    }

    widget.onRoomSelected.call(roomId);
  }

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
    return Column(
      children: [
        Expanded(
          child: UserSelector(
              client: widget.client,
              multipleUserSelectionEnabled: createGroup,
              onUserSelected: startChat,
              appBarBuilder: (bool isSearching) => Column(children: [
                    if (!isSearching && !createGroup)
                      ListTile(
                          title: const Text("Create group"),
                          leading: const Icon(Icons.group_add),
                          onTap: () {
                            setState(() {
                              createGroup = true;
                            });
                          }),
                    if (!isSearching && !createGroup)
                      ListTile(
                          title: const Text("Advanced option"),
                          subtitle: const Text(
                              "Configure E2E or create public group"),
                          leading: const Icon(Icons.groups),
                          onTap: advancedChatOption)
                  ]),
              controller: controller),
        ),
        const SizedBox(width: 10),
        if (createGroup)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              MaterialButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  color: Theme.of(context).colorScheme.onPrimary,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 60,
                      child: Center(
                        child: Text('Abort',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary)),
                      ),
                    ),
                  ),
                  onPressed: () => setState(() {
                        createGroup = false;
                        controller.selectedUsers.clear();
                      })),
              MaterialButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                color: Theme.of(context).colorScheme.primary,
                disabledColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                onPressed: _creating ? null : _createGroup,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      if (_creating)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.onPrimary),
                          ),
                        ),
                      Text('Create group',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary)),
                    ],
                  ),
                ),
              )
            ]),
          ),
      ],
    );
  }
}
