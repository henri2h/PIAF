import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../../user/user_info_dialog.dart';

class DirectChatWidget extends StatelessWidget {
  const DirectChatWidget({
    super.key,
    required this.room,
  });

  final Room room;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PresenceIndicator(room: room, userID: room.directChatMatrixID!),
      ],
    );
  }
}
