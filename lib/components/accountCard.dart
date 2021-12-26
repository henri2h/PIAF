import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';

class AccountCard extends StatelessWidget {
  AccountCard({Key? key, this.user, this.profile})
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
          padding: EdgeInsets.all(0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          context.pushRoute(UserViewRoute(userId: userId));
        },
        child: Column(
          children: [
            MatrixUserImage(
              client: Matrix.of(context).sclient,
              url: avatarUrl,
              defaultText: displayName,
              width: 80,
              height: 80,
              thumnail: true,
              rounded: false,
              backgroundColor: Colors.blue,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10)),
              defaultIcon: Icon(Icons.person,
                  color: Theme.of(context).textTheme.bodyText1!.color,
                  size: 70),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0, top: 2),
              child: SizedBox(
                width: 80,
                height: 35,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(displayName ?? userId,
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
              Text("Invited")
          ],
        ),
      ),
    );
  }
}
