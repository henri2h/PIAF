import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../../dialogs/adaptative_dialogs.dart';
import '../room_list/user_room_list.dart';

class MinesTrixUserSelection extends StatefulWidget {
  const MinesTrixUserSelection(
      {Key? key, this.participants, required this.room})
      : super(key: key);
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
                            Column(children: const []),
                        controller: controller);
                  }),
            ),
          ],
        ));
  }
}
