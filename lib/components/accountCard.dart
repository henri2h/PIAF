import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';

class AccountCard extends StatelessWidget {
  AccountCard({Key? key, this.user}) : super(key: key);
  final User? user;
  @override
  Widget build(BuildContext context) {
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
          if (user?.id != null)
            context.pushRoute(UserFeedRoute(userId: user?.id));
        },
        child: Column(
          children: [
            MatrixUserImage(
              client: Matrix.of(context).sclient,
              url: user!.avatarUrl,
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
                child: Text(user!.displayName!,
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
