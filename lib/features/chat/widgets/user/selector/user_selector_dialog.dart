import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/utils/matrix_widget.dart';

import '../../../../../partials/dialogs/adaptative_dialogs.dart';
import 'user_selector.dart';

class MinesTrixUserSelection extends StatefulWidget {
  const MinesTrixUserSelection(
      {super.key, this.participants, required this.room});
  final List<User>?
      participants; // list of the users who won't appear in the searchbox
  final Room room;
  static Future<List<String>?> show(BuildContext context, Room room) async {
    return await AdaptativeDialogs.show(
        context: context, builder: (a) => MinesTrixUserSelection(room: room));
  }

  @override
  MinesTrixUserSelectionState createState() => MinesTrixUserSelectionState();
}

class MinesTrixUserSelectionState extends State<MinesTrixUserSelection> {
  final controller = UserSelectorController();

  @override
  Widget build(BuildContext context) {
    Client? client = Matrix.of(context).client;

    return Scaffold(
        appBar: AppBar(
          title: const Text("Add users"),
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.pop(context, controller.selectedUsers);
                },
                icon: const Icon(Icons.done))
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<User>>(
                  future: widget.room.requestParticipants(),
                  builder: (context, snap) {
                    if (!snap.hasData) return const CircularProgressIndicator();
                    return UserSelector(
                        client: client,
                        ignoreUsers:
                            snap.data?.map((user) => user.id).toList() ?? [],
                        multipleUserSelectionEnabled: true,
                        onUserSelected: (_) {},
                        appBarBuilder: (bool isSearching) =>
                            const Column(children: []),
                        state: controller);
                  }),
            ),
          ],
        ));
  }
}
