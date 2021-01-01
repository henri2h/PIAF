import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:minestrix/components/MatrixUserImage.dart';
import 'package:minestrix/components/accountCard.dart';
import 'package:minestrix/components/pageTitle.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/global/smatrix.dart';

class FriendsVue extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final SClient sclient = Matrix.of(context).sclient;
    List<User> users = sclient.userRoom.room.getParticipants();
    List<User> friendRequest =
        users.where((User u) => u.membership == Membership.invite).toList();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitle("Users"),
          for (User u
              in users.where((User u) => u.membership == Membership.join))
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(u.displayName),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(u.id),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(u.membership.toString()),
                ),
              ],
            ),
          if (friendRequest.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Friend requests",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600)),
            ),
          for (User u in friendRequest)
            Row(
              children: [
                Text("Sent friend requests"),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(u.displayName),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(u.id),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(u.membership.toString()),
                ),
              ],
            ),
          TypeAheadField(
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
                leading: CircleAvatar(
                  backgroundImage: profile.avatarUrl == null
                      ? null
                      : NetworkImage(
                          profile.avatarUrl.getThumbnail(
                            sclient,
                            width: 64,
                            height: 64,
                          ),
                        ),
                ),
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
          Text("Can write on feed : "),
          Flexible(
            child: StreamBuilder(
                stream: sclient.onEvent.stream,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("Friend requests",
                              style: TextStyle(
                                  fontSize: 25, fontWeight: FontWeight.bold)),
                        ),
                        for (SMatrixRoom sm in sclient.sInvites.values)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  MatrixUserImage(user: sm.user),
                                  SizedBox(width: 10),
                                  Text(sm.user.displayName),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                      icon: Icon(Icons.check,
                                          color: Colors.green),
                                      onPressed: () async {
                                        await sm.room.join();
                                      }),
                                  IconButton(
                                      icon:
                                          Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        await sm.room.leave();
                                      }),
                                ],
                              ),
                            ],
                          ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("Friend",
                              style: TextStyle(
                                  fontSize: 25, fontWeight: FontWeight.bold)),
                        ),
                        Wrap(children: [
                          for (int i = 0; i < sclient.srooms.length; i++)
                            AccountCard(
                                user: sclient.srooms.values.toList()[i].user),
                        ]),
                      ],
                    )),
          ),
        ],
      ),
    );
  }
}
