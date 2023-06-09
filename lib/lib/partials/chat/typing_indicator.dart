import 'package:flutter/material.dart';

import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_5.dart';
import 'package:matrix/matrix.dart';

import '../matrix/matrix_image_avatar.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({
    Key? key,
    required this.room,
    required this.user,
  }) : super(key: key);

  final Room room;
  final User user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Row(
        children: [
          MatrixImageAvatar(
              client: room.client,
              url: user.avatarUrl,
              defaultText: user.displayName,
              backgroundColor: Theme.of(context).colorScheme.primary,
              height: 30,
              width: 30),
          const SizedBox(width: 10),
          ChatBubble(
              clipper: ChatBubbleClipper5(type: BubbleType.receiverBubble),
              child: Row(
                children: [
                  Text((user.displayName ?? user.id),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const Text(" is typing ",
                      style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 10),
                  const SizedBox(
                      height: 10,
                      width: 10,
                      child: CircularProgressIndicator(color: Colors.white)),
                ],
              ))
        ],
      ),
    );
  }
}
