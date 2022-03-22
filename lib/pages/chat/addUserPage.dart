import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';

class AddUserPage extends StatefulWidget {
  AddUserPage(BuildContext context, {Key? key}) : super(key: key);
  @override
  _AddUserPageState createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  List<Profile> profiles = [];

  @override
  Widget build(BuildContext context) {
    MinestrixClient? sclient = Matrix.of(context).sclient;
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
                var ur = await sclient!.searchUserDirectory(pattern);
                List<User?> following = List<User?>.empty();
                sclient.following.forEach((key, MinestrixRoom sroom) {
                  following.add(sroom.user);
                });

                return ur.results
                    .where((element) =>
                        following.firstWhere(
                            (friend) => friend!.id == element.userId,
                            orElse: () => null) ==
                        null)
                    .toList(); // exclude the users we are currently following
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
