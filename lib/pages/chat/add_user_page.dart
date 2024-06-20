import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/utils/minestrix/minestrix_client_extension.dart';
import 'package:piaf/partials/minestrix_chat.dart';
import 'package:piaf/partials/matrix/matrix_image_avatar.dart';
import 'package:piaf/partials/utils/matrix_widget.dart';

@RoutePage()
class AddUserPage extends StatefulWidget {
  const AddUserPage(BuildContext context, {super.key});
  @override
  AddUserPageState createState() => AddUserPageState();
}

class AddUserPageState extends State<AddUserPage> {
  List<Profile> profiles = [];

  @override
  Widget build(BuildContext context) {
    Client? client = Matrix.of(context).client;
    return Scaffold(
        appBar: AppBar(
          title: const Text("Add users"),
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.done))
          ],
        ),
        body: ListView(children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TypeAheadField(
              hideOnEmpty: true,
              builder: (context, controller, focusNode) => TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: false,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder())),
              suggestionsCallback: (pattern) async {
                var ur = await client.searchUserDirectory(pattern);
                List<User?> following = List<User?>.empty();
                for (var room in client.following) {
                  following.add(room.creator);
                }

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
                      ? const Icon(Icons.person)
                      : MatrixImageAvatar(
                          client: client, url: profile.avatarUrl),
                  title: Text((profile.displayName ?? profile.userId)),
                  subtitle: Text(profile.userId),
                );
              },
              onSelected: (dynamic suggestion) async {
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
                    client: client, url: p.avatarUrl, thumnailOnly: true),
                subtitle: Text(p.userId)),
        ]));
  }
}
