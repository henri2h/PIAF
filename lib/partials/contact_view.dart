import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:piaf/chat/partials/matrix/matrix_image_avatar.dart';
import 'package:piaf/chat/utils/matrix_widget.dart';

import '../router.gr.dart';
import '../utils/minestrix/minestrix_room.dart';

class ContactView extends StatelessWidget {
  const ContactView({
    super.key,
    required this.sroom,
  });
  final MinestrixRoom sroom;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: TextButton(
          onPressed: () {
            context.navigateTo(UserViewRoute(userID: sroom.userID));
          },
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      MatrixImageAvatar(
                        client: Matrix.of(context).client,
                        url: sroom.avatar,
                        width: 32,
                        height: 32,
                        defaultIcon: const Icon(Icons.person, size: 32),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                    (sroom.user?.displayName ??
                                        sroom.userID ??
                                        'null'),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .color)),
                                Text(
                                  sroom.userID!,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .color),
                                )
                              ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
        ),
      ),
    );
  }
}
