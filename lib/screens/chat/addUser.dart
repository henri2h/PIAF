import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';

class AddUser extends StatefulWidget {
  AddUser(BuildContext context, {Key key}) : super(key: key);
  @override
  _AddUserState createState() => _AddUserState();
}

class _AddUserState extends State<AddUser> {
  List<Profile> profiles = [];

  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    return Scaffold(
        appBar: AppBar(
          title: Text("Add users"),
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.pop(context);
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
                List<User> sFriends = await sclient.getSfriends();

                return ur.results
                    .where((element) =>
                        sFriends.firstWhere(
                            (friend) => friend.id == element.userId,
                            orElse: () => null) ==
                        null)
                    .toList(); // exclude current friends
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
