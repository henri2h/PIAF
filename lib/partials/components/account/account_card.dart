import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';
import 'package:piaf/pages/chat/room_page.dart';
import 'package:piaf/partials/dialogs/adaptative_dialogs.dart';
import 'package:piaf/partials/matrix/matrix_image_avatar.dart';

import 'package:piaf/router.gr.dart';
import 'package:piaf/partials/utils/matrix_widget.dart';

class AccountCard extends StatelessWidget {
  const AccountCard(
      {super.key, this.user, this.profile, this.displaySend = false})
      : assert(user != null || profile != null);

  final User? user;
  final Profile? profile;
  final bool displaySend;
  @override
  Widget build(BuildContext context) {
    late String userId;
    String? displayName;
    Uri? avatarUrl;

    if (user != null) {
      userId = user!.id;
      avatarUrl = user!.avatarUrl;
      displayName = user!.displayName;
    } else {
      userId = profile!.userId;
      avatarUrl = profile!.avatarUrl;
      displayName = profile!.displayName;
    }

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          context.pushRoute(UserViewRoute(userID: userId));
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            MatrixImageAvatar(
              client: Matrix.of(context).client,
              url: avatarUrl,
              defaultText: displayName,
              width: MinestrixAvatarSizeConstants.large,
              height: MinestrixAvatarSizeConstants.large,
              shape: MatrixImageAvatarShape.none,
              unconstraigned: true,
              backgroundColor: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.all(Radius.circular(10.0)),
              defaultIcon: Icon(Icons.person,
                  color: Theme.of(context).colorScheme.onPrimary, size: 70),
            ),
            Card(
              child: SizedBox(
                height: 46,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(displayName ?? userId,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .color)),
                      ),
                      if (displaySend)
                        IconButton(
                            onPressed: () {
                              final client = Matrix.of(context).client;
                              String? roomId =
                                  client.getDirectChatFromUserId(userId);
                              AdaptativeDialogs.show(
                                  context: context,
                                  builder: (BuildContext context) => RoomPage(
                                      roomId: roomId ?? userId,
                                      client: client,
                                      onBack: () => context.maybePop()));
                            },
                            icon: const Icon(Icons.send))
                    ],
                  ),
                ),
              ),
            ),
            if (user != null && user!.membership == Membership.invite)
              const Text("Invited")
          ],
        ),
      ),
    );
  }
}
