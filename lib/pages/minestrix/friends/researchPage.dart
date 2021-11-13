import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
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
              title: Text(profile.displayName!),
              subtitle: Text(profile.userId),
            );
          },
          onSuggestionSelected: (dynamic suggestion) async {
            Profile p = suggestion;
            //User u = User(p.userId, displayName: p.displayName);
            //NavigationHelper.navigateToUserFeed(context, u);
            // TODO : enable navigation to feed on suggestion selected
          },
        ),
      ),
    ]);
  }
}
