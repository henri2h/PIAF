import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../../chat_components/shimmer_widget.dart';
import '../../matrix/matrix_user_avatar.dart';

class UserItem extends StatelessWidget {
  const UserItem(
      {super.key,
      required this.avatarUrl,
      required this.client,
      required this.name,
      required this.userId,
      this.avatarHeight,
      this.avatarWidth,
      this.subtitle});

  UserItem.fromUser(User user,
      {super.key,
      required this.client,
      this.subtitle,
      this.avatarHeight,
      this.avatarWidth})
      : avatarUrl = user.avatarUrl,
        name = user.displayName,
        userId = user.id;

  final Uri? avatarUrl;
  final Client? client;
  final String? name;
  final String userId;
  final Widget? subtitle;
  final double? avatarWidth;
  final double? avatarHeight;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: MatrixUserAvatar(
          avatarUrl: avatarUrl,
          client: client,
          name: name,
          userId: userId,
          width: avatarWidth,
          height: avatarHeight),
      title: Text(
        name ?? userId,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: name != null
          ? Text(
              userId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            )
          : null,
      trailing: subtitle,
    );
  }
}

class MatrixUserItemShimmer extends StatelessWidget {
  const MatrixUserItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWidget(
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
            ),
          ),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Column(
                children: [
                  Container(
                    height: 11,
                    color: Colors.white,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, right: 20),
                    child: Container(
                      height: 9,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
