import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:minestrix/components/accountCard.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/global/smatrix/SMatrixRoom.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/global/smatrix.dart';

class FriendsVue extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final SClient sclient = Matrix.of(context).sclient;
    List<User> users = sclient.userRoom.room
        .getParticipants()
        .where((User u) => u.membership == Membership.join)
        .toList();
    /*List<User> friendRequest =
        users.where((User u) => u.membership == Membership.invite).toList();*/

    return ListView(
      children: [
        H1Title("Users"),
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
              print(p.userId);
              await sclient.addFriend(p.userId);
            },
          ),
        ),
        Flexible(
          child: StreamBuilder(
              stream: sclient.onEvent.stream,
              builder: (context, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: H2Title("Friend requests"),
                      ),
                      for (SMatrixRoom sm in sclient.sInvites.values)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                MinesTrixUserImage(url: sm.user.avatarUrl),
                                SizedBox(width: 10),
                                Text(sm.user.displayName),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                    icon:
                                        Icon(Icons.check, color: Colors.green),
                                    onPressed: () async {
                                      await sm.room.join();
                                    }),
                                IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      await sm.room.leave();
                                    }),
                              ],
                            ),
                          ],
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: H2Title("Friends"),
                      ),
                      Center(
                        child: Wrap(children: [
                          for (int i = 0; i < users.length; i++)
                            AccountCard(user: users[i]),
                        ]),
                      ),
                    ],
                  )),
        ),
      ],
    );
  }
}
