import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/pages/chat_lib/room_page.dart';
import 'package:minestrix/chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix/chat/utils/matrix_widget.dart';

import '../components/buttons/custom_future_button.dart';

class MessageButton extends StatelessWidget {
  final String userId;
  const MessageButton({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    return CustomFutureButton(
        icon: const Icon(Icons.message),
        padding: const EdgeInsets.all(6),
        expanded: false,
        onPressed: () async {
          String? roomId = client.getDirectChatFromUserId(userId);
          AdaptativeDialogs.show(
              context: context,
              builder: (BuildContext context) => RoomPage(
                  roomId: roomId ?? userId,
                  client: client,
                  onBack: () => context.popRoute()));
        },
        children: const [Text("Message")]);
  }
}
