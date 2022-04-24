import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:matrix/matrix.dart';

import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/partials/users/userAvatar.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrix_widget.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';

class UserInfo extends StatelessWidget {
  const UserInfo({Key? key, this.room, this.profile})
      : assert(profile != null || room != null),
        super(key: key);

  final Profile? profile;
  final Room? room;

  @override
  Widget build(BuildContext context) {
    Client sclient = Matrix.of(context).client;
    String? roomUrl = room?.avatar
        ?.getThumbnail(sclient,
            width: 1000, height: 800, method: ThumbnailMethod.scale)
        .toString();
    User? u = room?.creator;
    Profile p = profile ??
        Profile(
            userId: u!.id, displayName: u.displayName, avatarUrl: u.avatarUrl);

    bool isUserPage = p.userId == sclient.userID;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (AutoRouter.of(context).canNavigateBack)
              IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    AutoRouter.of(context).pop();
                  }),
            Expanded(child: H1Title(isUserPage ? "My account" : "User feed")),
            if (isUserPage)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
                child: Row(
                  children: [
                    IconButton(
                        icon: Icon(Icons.settings),
                        onPressed: () {
                          context.navigateTo(SettingsRoute());
                        }),
                  ],
                ),
              ),
          ],
        ),
        LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          // small screens
          if (constraints.maxWidth < 800 || room?.avatar == null)
            return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                if (roomUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 180),
                    child: CachedNetworkImage(imageUrl: roomUrl),
                  ),
                UserAvatar(
                  p: p,
                ),
              ],
            );

          // big screens
          return Container(
              decoration: roomUrl != null
                  ? BoxDecoration(
                      image: DecorationImage(
                          image: CachedNetworkImageProvider(roomUrl),
                          fit: BoxFit.cover),
                    )
                  : null,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
                child: Align(
                    alignment: p.avatarUrl != null
                        ? Alignment.centerLeft
                        : Alignment.center,
                    child: UserAvatar(p: p)),
              ));
        }),
      ],
    );
  }
}
