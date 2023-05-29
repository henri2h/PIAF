import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../matrix/matrix_image_avatar.dart';

class ReadReceiptsItem extends StatelessWidget {
  const ReadReceiptsItem({Key? key, required this.r, required this.room})
      : super(key: key);

  final Receipt r;
  final Room room;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Tooltip(
        message: "${r.user.calcDisplayname()} read ${timeago.format(r.time)}",
        child: MatrixImageAvatar(
            url: r.user.avatarUrl,
            defaultText: r.user.calcDisplayname(),
            width: 20,
            height: 20,
            textPadding: 4,
            backgroundColor: Theme.of(context).colorScheme.primary,
            fit: true,
            client: room.client),
      ),
    );
  }
}
