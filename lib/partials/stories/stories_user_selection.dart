import 'dart:io';

import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:piaf/partials/stories/stories_user_list_view.dart';
import 'package:piaf/partials/utils/extensions/matrix/stories_extension.dart';

class UserSelection extends StatefulWidget {
  const UserSelection(
      {super.key, required this.client, required this.controller});

  final Client client;
  final UserSelectionController controller;

  @override
  UserSelectionState createState() => UserSelectionState();
}

enum UserState { userNew, userInRoom, userToAdd, userIgnored, userToIgnore }

class UserSelectionState extends State<UserSelection> {
  List<bool> isSelected = [true, false, false];

  @override
  Widget build(BuildContext context) {
    UserSelectionController c = widget.controller;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ToggleButtons(
            borderRadius: BorderRadius.circular(15),
            fillColor: Colors.green,
            selectedColor: Colors.white,
            selectedBorderColor: Colors.green,
            constraints: const BoxConstraints(minHeight: 26, minWidth: 80),
            onPressed: (int index) {
              setState(() {
                for (int buttonIndex = 0;
                    buttonIndex < isSelected.length;
                    buttonIndex++) {
                  if (buttonIndex == index) {
                    isSelected[buttonIndex] = true;
                  } else {
                    isSelected[buttonIndex] = false;
                  }
                }
              });
            },
            isSelected: isSelected,
            children: const [
              Text(
                "New",
              ),
              Text("Selected"),
              Text("Ignored")
            ],
          ),
        ),
        if (isSelected[0])
          UserStorieUserListView(
              client: widget.client,
              title: const Padding(
                padding: EdgeInsets.all(14),
                child: Text("User suggestions",
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
              ),
              users: c.usersNew,
              dismissible: true,
              onDismissed: (_, String userID) {
                setState(() {
                  c.users[userID] = UserState.userToIgnore;
                });
              },
              iconButtons: (String userID) => [
                    if (!(Platform.isIOS && Platform.isAndroid)) // isMobile
                      IconButton(
                        icon: const Icon(Icons.archive, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            c.users[userID] = UserState.userToIgnore;
                          });
                        },
                      ),
                    IconButton(
                        icon: const Icon(Icons.person_add, color: Colors.green),
                        onPressed: () {
                          setState(() {
                            c.users[userID] = UserState.userToAdd;
                          });
                        })
                  ]),
        if (isSelected[1])
          UserStorieUserListView(
            client: widget.client,
            title: const Padding(
              padding: EdgeInsets.all(14),
              child: Text("Users",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
            ),
            users: c.usersInRoom,
            newState: UserState.userToAdd,
            newStateColor: Colors.green,
          ),
        if (isSelected[2])
          UserStorieUserListView(
              client: widget.client,
              users: c.usersToIgnore,
              title: const Padding(
                padding: EdgeInsets.all(14),
                child: Text("Ignored users",
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
              ),
              newState: UserState.userToIgnore,
              newStateColor: Colors.red,
              dismissible: true,
              onDismissed: (_, String userID) {
                setState(() {
                  c.users[userID] = UserState.userNew;
                });
              },
              iconButtons: (String userID) => [
                    if (!(Platform.isIOS && Platform.isAndroid)) // isMobile
                      IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          onPressed: () {
                            setState(() {
                              c.users[userID] = UserState.userNew;
                            });
                          })
                  ]),
      ],
    );
  }
}

class UserSelectionController {
  final Map<String, UserState> users = {};
  late Room room;
  late Client client;

  Future<bool> loadRoomParticipants() async {
    if (!room.participantListComplete) {
      await room.requestParticipants();
    }

    List<String> usersIn =
        room.getParticipants().map<String>((e) => e.id).toList();
    for (String u in usersIn) {
      users[u] = UserState.userInRoom;
    }

    return true;
  }

  /// Add the users to the specific rooms
  Future<void> performUserAdditions() async {
    // update the to ignore image list
    await client.setIgnoredUsers(
        usersToIgnore.map((MapEntry<String, UserState> e) => e.key).toList());

    // get users to add to the room
    for (String u in getUserCriteria([UserState.userToAdd])
        .map((MapEntry<String, UserState> e) => e.key)) {
      await room.invite(u);
    }
  }

  List<MapEntry<String, UserState>> getUserCriteria(List<UserState> criteria) {
    return users.entries
        .where((MapEntry<String, UserState> e) => criteria.contains(e.value))
        .toList()
      ..sort((MapEntry<String, UserState> a, MapEntry<String, UserState> b) =>
          a.value == b.value ? 0 : 1);
  }

  List<MapEntry<String, UserState>> get usersNew =>
      getUserCriteria([UserState.userNew]);
  List<MapEntry<String, UserState>> get usersInRoom =>
      getUserCriteria([UserState.userInRoom, UserState.userToAdd]);
  List<MapEntry<String, UserState>> get usersToIgnore =>
      getUserCriteria([UserState.userIgnored, UserState.userToIgnore]);

  UserSelectionController(
      {required this.client,
      required List<String> candidateUsers,
      required this.room}) {
    for (String u in candidateUsers) {
      if (users.containsKey(u) == false) users[u] = UserState.userNew;
    }

    for (String u in client.getIgnoredUsersForStories()) {
      users[u] = UserState.userIgnored;
    }
  }
}
