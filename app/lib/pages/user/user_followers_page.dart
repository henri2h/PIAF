import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';

import 'package:minestrix/partials/components/account/account_card.dart';
import 'package:minestrix/partials/components/minestrix/minestrix_title.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import 'package:minestrix_chat/minestrix_chat.dart';

import '../../partials/components/layouts/custom_header.dart';

@RoutePage()
class UserFollowersPage extends StatefulWidget {
  const UserFollowersPage({super.key, required this.room});

  final Room room;

  @override
  UserFollowersPageState createState() => UserFollowersPageState();
}

class UserFollowersPageState extends State<UserFollowersPage> {
  @override
  Widget build(BuildContext context) {
    final Client sclient = Matrix.of(context).client;
    List<User> users = widget.room
        .getParticipants()
        .where((User u) => u.membership == Membership.join)
        .toList();
    /*List<User> friendRequest =
        users.where((User u) => u.membership == Membership.invite).toList();*/

    return ListView(
      children: [
        FutureBuilder<Profile>(
            future: sclient.fetchOwnProfile(),
            builder: (context, snap) {
              if (!snap.hasData) return const CircularProgressIndicator();
              return Container(); //UserInfo(profile: snap.data!);
            }),
        const CustomHeader(title: "Followers"),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TypeAheadField(
            hideOnEmpty: true,
            builder: (context, controller, focusNode) => TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: false,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            suggestionsCallback: (pattern) async {
              var ur = await sclient.searchUserDirectory(pattern);

              List<User?> following = [];
              for (var room in sclient.following) {
                following.add(room.creator);
              }

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
                    ? const Icon(Icons.person)
                    : MatrixImageAvatar(
                        client: sclient, url: profile.avatarUrl),
                title: Text((profile.displayName ?? profile.userId)),
                subtitle: Text(profile.userId),
              );
            },
            onSelected: (dynamic suggestion) async {
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
                    const Padding(
                      padding: EdgeInsets.all(8.0),
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
                              const SizedBox(width: 10),
                              Text((sm.creator?.displayName ??
                                  sm.creatorId ??
                                  "null")),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.check,
                                      color: Colors.green),
                                  onPressed: () async {
                                    await sm.join();
                                  }),
                              IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () async {
                                    await sm.leave();
                                  }),
                            ],
                          ),
                        ],
                      ),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: H2Title("Friends"),
                    ),
                    Center(
                      child: Wrap(children: [
                        for (User user in users.where((User u) =>
                            u.membership == Membership.join &&
                            u.id != sclient.userID))
                          SizedBox(
                              width: 180,
                              height: 200,
                              child: AccountCard(user: user)),
                      ]),
                    ),
                  ],
                )),
      ],
    );
  }
}
