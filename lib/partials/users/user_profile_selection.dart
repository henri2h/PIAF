import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/utils/profile_space.dart';

import '../../pages/minestrix/user/unknown_user.dart';

class UserProfileSelection extends StatefulWidget {
  const UserProfileSelection(
      {Key? key,
      required this.userId,
      required this.onRoomSelected,
      required this.roomSelectedId})
      : super(key: key);
  final String userId;
  final String? roomSelectedId;
  final void Function(Room r) onRoomSelected;

  @override
  _UserProfileSelectionState createState() => _UserProfileSelectionState();
}

class _UserProfileSelectionState extends State<UserProfileSelection> {
  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;

    final _rooms = client.sroomsByUserId[widget.userId]?.toList() ?? [];

    bool isOurProfile = widget.userId == client.userID;

    ProfileSpace? profile = ProfileSpace.getProfileSpace(client);

    return Column(
      children: [
        if (_rooms.length > 1 || isOurProfile)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MaterialButton(
                    padding: EdgeInsets.all(2),
                    disabledTextColor:
                        Theme.of(context).colorScheme.onBackground,
                    onPressed: isOurProfile
                        ? () {
                            context.pushRoute(AccountsDetailsRoute());
                          }
                        : null,
                    child: H2Title("User profiles")),
                if (profile == null && isOurProfile)
                  Card(
                    child: ListTile(
                        leading: Icon(Icons.create_new_folder),
                        title: Text("No profile space found"),
                        subtitle: Text("Go to settings to create one")),
                  ),
                for (final r in _rooms)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: MaterialButton(
                        color: r.id == widget.roomSelectedId
                            ? Theme.of(context).primaryColor
                            : null,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              MatrixImageAvatar(
                                client: client,
                                url: r.avatar,
                                thumnail: true,
                                defaultText: r.topic,
                                backgroundColor: Theme.of(context).primaryColor,
                                shape: MatrixImageAvatarShape.rounded,
                                width: 45,
                                height: 45,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 100),
                                child: Text(r.displayname,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: r.id == widget.roomSelectedId
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                            : null,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            widget.onRoomSelected(r);
                          });
                        }),
                  ),
              ],
            ),
          ),
        ProfileDiscovery(userId: widget.userId, client: client)
      ],
    );
  }
}
