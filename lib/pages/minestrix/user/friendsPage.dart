import 'package:matrix/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:minestrix/partials/components/account/accountCard.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/partials/users/userInfo.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  @override
  Widget build(BuildContext context) {
    final MinestrixClient sclient = Matrix.of(context).sclient!;
    List<User> users = sclient.userRoom!.room
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
              sclient.following.forEach((key, MinestrixRoom sroom) {
                following.add(sroom.user);
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
                    : MatrixUserImage(client: sclient, url: profile.avatarUrl),
                title: Text((profile.displayName ?? profile.userId)),
                subtitle: Text(profile.userId),
              );
            },
            onSuggestionSelected: (dynamic suggestion) async {
              Profile p = suggestion;
              await sclient.addFriend(p.userId);
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
                      child: H2Title("Friend requests : "),
                    ),
                    for (MinestrixRoom sm in sclient.minestrixInvites.values)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              MatrixUserImage(
                                  client: sclient, url: sm.user?.avatarUrl),
                              SizedBox(width: 10),
                              Text((sm.user?.displayName ??
                                  sm.userID ??
                                  "null")),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                  icon: Icon(Icons.check, color: Colors.green),
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
