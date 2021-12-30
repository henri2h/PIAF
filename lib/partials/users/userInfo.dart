import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/partials/users/userAvatar.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';

class UserInfo extends StatelessWidget {
  const UserInfo({Key? key, required this.profile, this.room})
      : super(key: key);

  final Profile profile;
  final Room? room;

  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;
    String? roomUrl = room?.avatar
        ?.getThumbnail(sclient,
            width: 1000, height: 800, method: ThumbnailMethod.scale)
        .toString();

    bool isUserPage = profile.userId == sclient.userID;
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
                  p: profile,
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
                    alignment: profile.avatarUrl != null
                        ? Alignment.centerLeft
                        : Alignment.center,
                    child: UserAvatar(p: profile)),
              ));
        }),
      ],
    );
  }
}
