import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'matrix_image_avatar.dart';

class UserDisplay extends StatelessWidget {
  const UserDisplay({super.key, required this.client, this.showUserName = true});

  final Client client;
  final bool showUserName;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: client.getProfileFromUserId(client.userID!),
        builder: (BuildContext context, AsyncSnapshot<Profile> p) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              p.data?.avatarUrl != null
                  ? MatrixImageAvatar(
                      client: client,
                      url: p.data!.avatarUrl,
                      fit: true,
                      width: MinestrixAvatarSizeConstants.small,
                      height: MinestrixAvatarSizeConstants.small)
                  : const Icon(Icons.person),
              if (showUserName) const SizedBox(width: 12),
              if (showUserName)
                Expanded(
                  child: Text(p.data?.displayName ?? client.userID!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 20)),
                ),
            ]),
          );
        });
  }
}
