import 'package:matrix/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';

class MinesTrixUserSelection extends StatefulWidget {
  MinesTrixUserSelection({Key? key, this.participants}) : super(key: key);
  final List<User?>?
      participants; // list of the users who won't appear in the searchbox
  @override
  _MinesTrixUserSelectionState createState() => _MinesTrixUserSelectionState();
}

class _MinesTrixUserSelectionState extends State<MinesTrixUserSelection> {
  List<Profile> profiles = [];
  List<User?>? participants;

  @override
  Widget build(BuildContext context) {
    MinestrixClient? sclient = Matrix.of(context).sclient;

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
                var ur = await sclient!.searchUserDirectory(pattern);
                if (participants == null) participants = widget.participants;

                // by default we remove the users followed by the user
                if (participants == null) {
                  participants = List<User?>.empty();

                  sclient.following.forEach((key, MinestrixRoom sroom) {
                    participants!.add(sroom.user);
                  });
                }

                return ur.results
                    .where((element) =>
                        widget.participants!.firstWhere(
                            (friend) => friend!.id == element.userId,
                            orElse: () => null) ==
                        null)
                    .toList(); // exclude current participants (we cannot add them twice)
              },
              itemBuilder: (context, dynamic suggestion) {
                Profile profile = suggestion;
                return ListTile(
                  leading: profile.avatarUrl == null
                      ? Icon(Icons.person)
                      : MatrixUserImage(
                          client: sclient, url: profile.avatarUrl),
                  title: Text(profile.displayName!),
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
                title: Text(p.displayName!),
                leading: MatrixUserImage(
                    client: sclient, url: p.avatarUrl, thumnail: true),
                subtitle: Text(p.userId)),
        ]));
  }
}
