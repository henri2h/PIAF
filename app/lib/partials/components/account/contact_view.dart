import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

class ContactView extends StatelessWidget {
  const ContactView({
    super.key,
    required this.user,
  });
  final User user;
  @override
  Widget build(BuildContext context) {
    return ListTile(
        onTap: () {
          context.navigateTo(UserViewRoute(userID: user.id));
        },
        leading: MatrixImageAvatar(
            client: Matrix.of(context).client,
            url: user.avatarUrl,
            defaultText: user.displayName,
            width: 48,
            height: 48),
        title: Text((user.displayName ?? user.id),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            )),
        subtitle: Text(
          user.id,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: (user.canKick || user.canBan)
            ? PopupMenuButton<String>(
                itemBuilder: (_) => [
                      if (user.canKick)
                        const PopupMenuItem(
                            value: "kick",
                            child: Row(
                              children: [
                                Icon(Icons.person_remove),
                                SizedBox(width: 10),
                                Text("Kick"),
                              ],
                            )),
                      if (user.canBan)
                        const PopupMenuItem(
                            value: "ban",
                            child: Row(
                              children: [
                                Icon(Icons.delete_forever, color: Colors.red),
                                SizedBox(width: 10),
                                Text("Ban",
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ))
                    ],
                icon: const Icon(Icons.more_vert),
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
            : null);
  }
}
