import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/matrix_widget.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';

class AddUserPage extends StatefulWidget {
  AddUserPage(BuildContext context, {Key? key}) : super(key: key);
  @override
  _AddUserPageState createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  List<Profile> profiles = [];

  @override
  Widget build(BuildContext context) {
    Client? client = Matrix.of(context).client;
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
                var ur = await client.searchUserDirectory(pattern);
                List<User?> following = List<User?>.empty();
                client.following.forEach((room) {
                  following.add(room.creator);
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
                          client: client, url: profile.avatarUrl),
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
                    client: client, url: p.avatarUrl, thumnail: true),
                subtitle: Text(p.userId)),
        ]));
  }
}
