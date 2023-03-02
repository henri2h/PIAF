import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';

import 'package:minestrix/router.gr.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({Key? key, this.user, this.profile})
      : assert(user != null || profile != null),
        super(key: key);

  final User? user;
  final Profile? profile;

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
          primary: Theme.of(context).cardColor,
          padding: const EdgeInsets.all(0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          context.pushRoute(UserViewRoute(userID: userId));
        },
        child: Column(
          children: [
            MatrixImageAvatar(
              client: Matrix.of(context).client,
              url: avatarUrl,
              defaultText: displayName,
              width: MinestrixAvatarSizeConstants.large,
              height: MinestrixAvatarSizeConstants.large,
              shape: MatrixImageAvatarShape.none,
              backgroundColor: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10)),
              defaultIcon: Icon(Icons.person,
                  color: Theme.of(context).colorScheme.onPrimary, size: 70),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 5),
              child: SizedBox(
                width: MinestrixAvatarSizeConstants.large,
                height: 30,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(displayName ?? userId,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color:
                                Theme.of(context).textTheme.bodyText1!.color)),
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
