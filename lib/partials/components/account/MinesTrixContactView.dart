import 'package:flutter/material.dart';

import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';

import 'package:minestrix/router.gr.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

class MinesTrixContactView extends StatelessWidget {
  const MinesTrixContactView({
    Key? key,
    required this.user,
  }) : super(key: key);
  final User user;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: MaterialButton(
          onPressed: () {
            context.navigateTo(UserViewRoute(userID: user.id));
          },
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        MatrixImageAvatar(
                            client: Matrix.of(context).client,
                            url: user.avatarUrl,
                            width: 48,
                            thumnail: true,
                            height: 48),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text((user.displayName ?? user.id),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      )),
                                  Text(
                                    user.id,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ]),
                          ),
                        ),
                        if (user.canKick || user.canBan)
                          PopupMenuButton<String>(
                              itemBuilder: (_) => [
                                    if (user.canKick)
                                      PopupMenuItem(
                                          child: Row(
                                            children: [
                                              Icon(Icons.person_remove),
                                              SizedBox(width: 10),
                                              Text("Kick"),
                                            ],
                                          ),
                                          value: "kick"),
                                    if (user.canBan)
                                      PopupMenuItem(
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_forever,
                                                  color: Colors.red),
                                              SizedBox(width: 10),
                                              Text("Ban",
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                            ],
                                          ),
                                          value: "ban")
                                  ],
                              icon: Icon(Icons.more_horiz),
                              onSelected: (String action) async {
                                switch (action) {
                                  case "kick":
                                    await user.kick();
                                    break;
                                  case "ban":
                                    await user.ban();
                                    break;
                                  default:
                                }
                              })
                      ],
                    ),
                  ),
                ]),
          ),
        ),
      ),
    );
  }
}
