import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/global/helpers/NavigationHelper.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';

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
            UserSearchResult ur = await sclient.searchUser(pattern);
            List<User> sFriends = await sclient.getSfriends();

            return ur.results
                .where((element) =>
                    sFriends.firstWhere((friend) => friend.id == element.userId,
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
            User u = User(p.userId, displayName: p.displayname);
            NavigationHelper.navigateToUserFeed(context, u);
          },
        ),
      ),
    ]);
  }
}
