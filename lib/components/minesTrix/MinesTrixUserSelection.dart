import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrix/SMatrixRoom.dart';
import 'package:minestrix/global/smatrixWidget.dart';

class MinesTrixUserSelection extends StatefulWidget {
  MinesTrixUserSelection({Key key, this.participants}) : super(key: key);
  final List<User>
      participants; // list of the users who won't appear in the searchbox
  @override
  _MinesTrixUserSelectionState createState() => _MinesTrixUserSelectionState();
}

class _MinesTrixUserSelectionState extends State<MinesTrixUserSelection> {
  List<Profile> profiles = [];
  List<User> participants;

  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;

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
                UserSearchResult ur = await sclient.searchUser(pattern);
                if (participants == null) participants = widget.participants;

                // by default we remove the users followed by the user
                if (participants == null) {
                  participants = List<User>.empty();

                  await sclient.following.forEach((key, SMatrixRoom sroom) {
                    participants.add(sroom.user);
                  });
                }

                return ur.results
                    .where((element) =>
                        widget.participants.firstWhere(
                            (friend) => friend.id == element.userId,
                            orElse: () => null) ==
                        null)
                    .toList(); // exclude current participants (we cannot add them twice)
              },
              itemBuilder: (context, suggestion) {
                Profile profile = suggestion;
                return ListTile(
                  leading: profile.avatarUrl == null
                      ? Icon(Icons.person)
                      : MinesTrixUserImage(url: profile.avatarUrl),
                  title: Text(profile.displayname),
                  subtitle: Text(profile.userId),
                );
              },
              onSuggestionSelected: (suggestion) async {
                Profile p = suggestion;
                setState(() {
                  profiles.add(p);
                });
              },
            ),
          ),
          for (Profile p in profiles)
            ListTile(
                title: Text(p.displayname),
                leading: MinesTrixUserImage(url: p.avatarUrl, thumnail: true),
                subtitle: Text(p.userId)),
        ]));
  }
}
