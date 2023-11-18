import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';
import 'package:shimmer/shimmer.dart';

import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/partials/stories/stories_user_selection.dart';

class UserStorieUserListView extends StatefulWidget {
  const UserStorieUserListView(
      {super.key,
      required this.client,
      required this.users,
      this.iconButtons,
      this.newState,
      this.newStateColor,
      this.dismissible = false,
      this.onDismissed,
      this.title})
      : assert(!dismissible || onDismissed != null);
  final Client client;
  final List<MapEntry<String, UserState>> users;
  final List<Widget> Function(String userID)? iconButtons;
  final void Function(DismissDirection, String)? onDismissed;
  final UserState? newState;
  final Color? newStateColor;
  final bool dismissible;
  final Widget? title;

  @override
  UserStorieUserListViewState createState() => UserStorieUserListViewState();
}

class UserStorieUserListViewState extends State<UserStorieUserListView> {
  final double _itemHeight = 50;
  ScrollController? _c;

  @override
  Widget build(BuildContext context) {
    _c ??
        ScrollController(
            initialScrollOffset: _itemHeight * widget.users.length);

    return Expanded(
      child: ListView.builder(
          itemCount: widget.title != null
              ? widget.users.length + 1
              : widget.users.length,
          itemExtent: 50,
          cacheExtent: 100,
          controller: _c,
          itemBuilder: (context, pos) {
            if (widget.title != null) {
              if (pos == 0) {
                return widget.title!;
              }
              pos--;
            }

            MapEntry<String, UserState> user = widget.users[pos];
            String userID = user.key;
            UserState userState = user.value;

            if (widget.dismissible) {
              return Dismissible(
                key: Key("lt_d_$userID"),
                onDismissed: (d) {
                  widget.onDismissed!(d, userID);
                },
                child: UserListViewTile(
                    userID: userID,
                    userState: userState,
                    client: widget.client,
                    iconButtons: widget.iconButtons,
                    newState: widget.newState,
                    newStateColor: widget.newStateColor),
              );
            }
            // if dissmissible is not enabled
            return UserListViewTile(
                userID: userID,
                userState: userState,
                client: widget.client,
                iconButtons: widget.iconButtons,
                newState: widget.newState,
                newStateColor: widget.newStateColor);
          }),
    );
  }
}

class UserListViewTile extends StatelessWidget {
  const UserListViewTile(
      {super.key,
      required this.userID,
      required this.client,
      required this.userState,
      required this.newState,
      required this.newStateColor,
      required this.iconButtons});

  final String userID;
  final UserState userState;
  final Client client;
  final List<Widget> Function(String userID)? iconButtons;
  final UserState? newState;
  final Color? newStateColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: Key("lt_$userID"),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: FutureBuilder<ProfileInformation>(
          future: client.getUserProfile(userID),
          builder: (context, snap) {
            // loading placeholder
            if (snap.hasData == false) {
              return Shimmer.fromColors(
                baseColor: Colors.white,
                highlightColor: Colors.green,
                child: Shimmer.fromColors(
                    baseColor: Colors.white,
                    highlightColor: Colors.green,
                    child: Row(children: [
                      MatrixImageAvatar(
                          client: client,
                          url: null,
                          fit: true,
                          thumnailOnly: true),
                      Expanded(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(userID)),
                      ),
                      if (iconButtons != null)
                        for (Widget i in iconButtons!(userID)) i
                    ])),
              );
            }
            ProfileInformation p = snap.data!;

            return Row(
              children: [
                MatrixImageAvatar(client: client, url: p.avatarUrl, fit: true),
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(p.displayname ?? userID,
                      style: TextStyle(
                          fontSize: 16,
                          color: userState == newState ? newStateColor : null)),
                )),
                if (iconButtons != null)
                  for (Widget i in iconButtons!(userID)) i
              ],
            );
          }),
    );
  }
}
