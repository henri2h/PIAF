import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';

class MinesTrixUserSelection extends StatefulWidget {
  MinesTrixUserSelection(
      {Key? key, this.participants, this.ignoreUserFollowingUser = false})
      : super(key: key);
  final List<User>?
      participants; // list of the users who won't appear in the searchbox
  final bool ignoreUserFollowingUser;
  @override
  _MinesTrixUserSelectionState createState() => _MinesTrixUserSelectionState();
}

class _MinesTrixUserSelectionState extends State<MinesTrixUserSelection> {
  List<Profile> profiles = [];
  List<User>? participants;

  @override
  Widget build(BuildContext context) {
    Client? sclient = Matrix.of(context).client;

    return Scaffold(
        appBar: AppBar(
          title: Text("Add users"),
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.pop(context, profiles);
                },
                icon: Icon(Icons.done))
          ],
        ),
        body: ListView(children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TypeAheadField(
              hideOnEmpty: true,
              textFieldConfiguration: TextFieldConfiguration(
                  autofocus: false,
                  decoration: InputDecoration(border: OutlineInputBorder())),
              suggestionsCallback: (pattern) async {
                var ur = await sclient.searchUserDirectory(pattern, limit: 20);
                if (participants == null) participants = widget.participants;

                if (participants == null) participants = List<User>.empty();

                if (widget.ignoreUserFollowingUser) {
                  // add the user following the user in the ignore list
                  sclient.following.forEach((room) {
                    final creator = room.creator;
                    if (creator != null) {
                      participants!.add(creator);
                    }
                  });
                }

                // calculate the difference between the particiants and the search results
                ur.results.removeWhere((user) =>
                    participants
                        ?.indexWhere((friend) => friend.id == user.userId) !=
                    -1);

                ur.results.removeWhere((user) =>
                    profiles
                        .indexWhere((friend) => friend.userId == user.userId) !=
                    -1);
                return ur
                    .results; // exclude current participants (we cannot add them twice)
              },
              itemBuilder: (context, dynamic suggestion) {
                Profile profile = suggestion;
                return ListTile(
                  leading: profile.avatarUrl == null
                      ? Icon(Icons.person)
                      : MatrixImageAvatar(
                          client: sclient, url: profile.avatarUrl),
                  title: Text((profile.displayName ?? profile.userId)),
                  subtitle: Text(profile.userId),
                );
              },
              onSuggestionSelected: (dynamic suggestion) async {
                Profile p = suggestion;
                setState(() {
                  profiles.add(p);
                });
              },
            ),
          ),
          for (Profile p in profiles)
            ListTile(
                title: Text((p.displayName ?? p.userId)),
                leading: MatrixImageAvatar(
                    client: sclient, url: p.avatarUrl, thumnail: true),
                subtitle: Text(p.userId)),
        ]));
  }
}
