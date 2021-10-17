import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/global/helpers/NavigationHelper.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';

class ResearchView extends StatefulWidget {
  @override
  _ResearchViewState createState() => _ResearchViewState();
}

class _ResearchViewState extends State<ResearchView> {
  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
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
            var ur = await sclient.searchUserDirectory(pattern);
            return ur.results.toList();
          },
          itemBuilder: (context, suggestion) {
            Profile profile = suggestion;
            return ListTile(
              leading: profile.avatarUrl == null
                  ? Icon(Icons.person)
                  : MatrixUserImage(client: sclient, url: profile.avatarUrl),
              title: Text(profile.displayName),
              subtitle: Text(profile.userId),
            );
          },
          onSuggestionSelected: (suggestion) async {
            Profile p = suggestion;
            User u = User(p.userId, displayName: p.displayName);
            NavigationHelper.navigateToUserFeed(context, u);
          },
        ),
      ),
    ]);
  }
}
