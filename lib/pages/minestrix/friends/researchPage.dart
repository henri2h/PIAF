import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/layouts/customHeader.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/partials/minestrixRoomTile.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrix_widget.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';

class ResearchPage extends StatefulWidget {
  @override
  _ResearchPageState createState() => _ResearchPageState();
}

class _ResearchPageState extends State<ResearchPage> {
  @override
  Widget build(BuildContext context) {
    Client? client = Matrix.of(context).client;
    return ListView(children: [
      CustomHeader("Search"),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TypeAheadField(
          hideOnEmpty: true,
          textFieldConfiguration: TextFieldConfiguration(
              autofocus: false,
              decoration: InputDecoration(border: OutlineInputBorder())),
          suggestionsCallback: (pattern) async {
            var ur = await client.searchUserDirectory(pattern);
            return ur.results.toList();
          },
          itemBuilder: (context, dynamic suggestion) {
            Profile profile = suggestion;
            return ListTile(
              leading: profile.avatarUrl == null
                  ? Icon(Icons.person)
                  : MatrixImageAvatar(client: client, url: profile.avatarUrl),
              title: Text((profile.displayName ?? profile.userId)),
              subtitle: Text(profile.userId),
            );
          },
          onSuggestionSelected: (Profile p) async {
            context.navigateTo(UserViewRoute(userID: p.userId));
          },
        ),
      ),
      StreamBuilder(
        stream: client.onSync.stream,
        builder: (context, _) =>
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          H2Title("Contacts"),
          for (Room r in client.sfriends) MinestrixRoomTile(room: r),
          H2Title("Groups"),
          for (Room r in client.sgroups) MinestrixRoomTile(room: r),
        ]),
      )
    ]);
  }
}
