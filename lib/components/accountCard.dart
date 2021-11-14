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
      padding: const EdgeInsets.all(6.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: Theme.of(context).cardColor,
          padding: EdgeInsets.all(0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          context.pushRoute(UserFeedRoute(userId: userId));
        },
        child: Column(
          children: [
            MatrixUserImage(
              client: Matrix.of(context).sclient,
              url: avatarUrl,
              width: 110,
              height: 110,
              thumnail: true,
              defaultIcon: Icon(Icons.person,
                  color: Theme.of(context).textTheme.bodyText1!.color,
                  size: 70),
            ),
            SizedBox(
              width: 100,
              height: 40,
              child: Center(
                child: Text(displayName ?? 'null',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Theme.of(context).textTheme.bodyText1!.color)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
