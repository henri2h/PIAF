import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/partials/minestrixRoomTile.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';

class ResearchPage extends StatefulWidget {
  @override
  _ResearchPageState createState() => _ResearchPageState();
}

class _ResearchPageState extends State<ResearchPage> {
  @override
  Widget build(BuildContext context) {
    MinestrixClient? sclient = Matrix.of(context).sclient;
    return ListView(children: [
      H1Title("Search"),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TypeAheadField(
          hideOnEmpty: true,
          textFieldConfiguration: TextFieldConfiguration(
              autofocus: false,
              decoration: InputDecoration(border: OutlineInputBorder())),
          suggestionsCallback: (pattern) async {
            var ur = await sclient!.searchUserDirectory(pattern);
            return ur.results.toList();
          },
          itemBuilder: (context, dynamic suggestion) {
            Profile profile = suggestion;
            return ListTile(
              leading: profile.avatarUrl == null
                  ? Icon(Icons.person)
                  : MatrixUserImage(client: sclient, url: profile.avatarUrl),
              title: Text((profile.displayName ?? profile.userId)),
              subtitle: Text(profile.userId),
            );
          },
          onSuggestionSelected: (Profile p) async {
            context.pushRoute(UserViewRoute(userId: p.userId));
          },
        ),
      ),
      StreamBuilder(
        stream: sclient!.onSync.stream,
        builder: (context, _) =>
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          H2Title("Contacts"),
          for (MinestrixRoom r in sclient.sfriends.values)
            MinestrixRoomTile(sroom: r),
          H2Title("Groups"),
          for (MinestrixRoom r in sclient.sgroups.values)
            MinestrixRoomTile(sroom: r),
        ]),
      )
    ]);
  }
}
