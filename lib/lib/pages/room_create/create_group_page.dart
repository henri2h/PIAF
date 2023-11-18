import 'package:flutter/material.dart' hide Visibility;
import 'package:matrix/matrix.dart';

import '../../partials/chat/user/selector/user_selector.dart';
import '../../partials/dialogs/adaptative_dialogs.dart';
import '../matrix_create_group.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage(
      {super.key, required this.onRoomSelected, required this.client});

  final Client client;
  final Function(String?) onRoomSelected;

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
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
        title: const Text("Create group"),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: _creating ? null : _createGroup,
          child: _creating
              ? const CircularProgressIndicator()
              : const Icon(Icons.create)),
      body: Column(
        children: [
          Expanded(
            child: UserSelector(
                client: widget.client,
                multipleUserSelectionEnabled: true,
                onUserSelected: (_) {},
                appBarBuilder: (bool isSearching) => Container(),
                state: controller),
          ),
        ],
      ),
    );
  }
}
