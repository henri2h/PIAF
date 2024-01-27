import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/chat/minestrix_chat.dart';

import '../matrix_message.dart';
import 'text_message_bubble.dart';

class AnimatedTextMessageBuble extends StatelessWidget {
  const AnimatedTextMessageBuble(
      {super.key,
      required AnimationController resizableController,
      required this.redacted,
      required this.widget,
      required this.noticeForegroundColor,
      required this.noticeBackgroundColor,
      required this.e})
      : _resizableController = resizableController;

  final AnimationController _resizableController;
  final bool redacted;
  final MessageDisplay widget;
  final Color noticeForegroundColor;
  final Color noticeBackgroundColor;
  final Event e;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _resizableController,
        builder: (BuildContext context, Widget? child) => TextMessageBubble(
              redacted: redacted,
              event: e,
              displaySentIndicator: widget.isLastMessage && e.sentByUser,
              edited: widget.edited,
              color: noticeForegroundColor,
              backgroundColor: noticeBackgroundColor,
              borderColor: () {
                // annimation when jumping to an event

                var pos = _resizableController.value;
                if (pos == 0 || pos == 1) {
                  return noticeBackgroundColor;
                }

                const duration = 0.15;
                const end = 1 - duration;

                if (pos < duration) {
                  pos = pos / duration;
                } else if (pos > end) {
                  pos = 1 - (pos - end) / duration;
                } else {
                  pos = 1;
                }
                return Color.lerp(
                    noticeBackgroundColor, Colors.blue.shade800, pos);
              }(),
            ));
  }
}
