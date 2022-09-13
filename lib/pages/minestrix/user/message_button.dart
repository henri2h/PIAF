import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/view/room_page.dart';

import '../../../partials/components/buttons/custom_future_button.dart';

class MessageButton extends StatelessWidget {
  final String userId;
  const MessageButton({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    return CustomFutureButton(
        icon: const Icon(Icons.message),
        padding: const EdgeInsets.all(6),
        expanded: false,
        onPressed: () async {
          String? roomId = await client.startDirectChat(userId);
          AdaptativeDialogs.show(
              context: context,
              builder: (BuildContext context) => RoomPage(
                  roomId: roomId,
                  client: client,
                  onBack: () => context.popRoute()));
        },
        children: const [Text("Message")]);
  }
}
