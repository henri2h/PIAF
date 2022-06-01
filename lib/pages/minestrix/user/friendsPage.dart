import 'package:flutter/material.dart';

import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';

import 'package:minestrix/partials/components/account/account_card.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/partials/users/userInfo.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import 'package:minestrix_chat/utils/matrix/room_extension.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  @override
  Widget build(BuildContext context) {
    final Client sclient = Matrix.of(context).client;
    List<User> users = sclient.minestrixUserRoom.first
        .getParticipants()
        .where((User u) => u.membership == Membership.join)
        .toList();
    /*List<User> friendRequest =
        users.where((User u) => u.membership == Membership.invite).toList();*/

    return ListView(
      children: [
        FutureBuilder<Profile>(
            future: sclient.ownProfile,
            builder: (context, snap) {
              if (!snap.hasData) return CircularProgressIndicator();
              return UserInfo(profile: snap.data!);
            }),
        H1Title("Following"),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TypeAheadField(
            hideOnEmpty: true,
            textFieldConfiguration: TextFieldConfiguration(
                autofocus: false,
                decoration: InputDecoration(border: OutlineInputBorder())),
            suggestionsCallback: (pattern) async {
              var ur = await sclient.searchUserDirectory(pattern);

              List<User?> following = [];
              sclient.following.forEach((room) {
                following.add(room.creator);
              });

              return ur.results
                  .where((element) =>
                      following.firstWhere(
                          (friend) => friend!.id == element.userId,
                          orElse: () => null) ==
                      null)
                  .toList(); // exclude current friends
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
              await sclient.inviteFriend(p.userId);
              setState(() {}); // update ui
            },
          ),
        ),
        StreamBuilder(
            stream: sclient.onEvent.stream,
            builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: H2Title("Friend requests : "),
                    ),
                    for (Room sm in sclient.minestrixInvites)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              MatrixImageAvatar(
                                  client: sclient, url: sm.creator?.avatarUrl),
                              SizedBox(width: 10),
                              Text((sm.creator?.displayName ??
                                  sm.creatorId ??
                                  "null")),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                  icon: Icon(Icons.check, color: Colors.green),
                                  onPressed: () async {
                                    await sm.join();
                                  }),
                              IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await sm.leave();
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
                        for (User user in users.where((User u) =>
                            u.membership == Membership.join &&
                            u.id != sclient.userID))
                          AccountCard(user: user),
                      ]),
                    ),
                  ],
                )),
      ],
    );
  }
}
