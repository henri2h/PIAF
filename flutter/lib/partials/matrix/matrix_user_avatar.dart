import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'matrix_image_avatar.dart';

class MatrixUserAvatar extends StatelessWidget {
  const MatrixUserAvatar({
    super.key,
    required this.avatarUrl,
    required this.client,
    required this.name,
    required this.userId,
    this.height,
    this.width,
    Uri? url,
  });

  MatrixUserAvatar.fromUser(User user,
      {super.key, required this.client, this.height, this.width})
      : avatarUrl = user.avatarUrl,
        name = user.displayName,
        userId = user.id;

  final Uri? avatarUrl;
  final Client? client;
  final String? name;
  final String userId;

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        MatrixImageAvatar(
          url: avatarUrl,
          client: client,
          height: height,
          width: width,
          fit: true,
          defaultIcon: const Icon(Icons.person, size: 40),
          defaultText: name ?? userId,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
}
