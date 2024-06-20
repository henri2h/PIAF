import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/minestrix_chat.dart';

import '../../event_widget.dart';
import 'text_message/text_message_bubble.dart';

class AnimatedTextMessageBuble extends StatelessWidget {
  const AnimatedTextMessageBuble(
      {super.key,
      required AnimationController resizableController,
      required this.redacted,
      required this.widget,
      required this.noticeForegroundColor,
      required this.noticeBackgroundColor,
      required this.e})
      : animationController = resizableController;

  final AnimationController animationController;
  final bool redacted;
  final EventWidget widget;
  final Color noticeForegroundColor;
  final Color noticeBackgroundColor;
  final Event e;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: animationController,
        builder: (BuildContext context, Widget? child) => TextMessageBubble(
              redacted: redacted,
              event: e,
              showSentIndicator: widget.isLastMessage && e.sentByUser,
              showSenderName: widget.displayName,
              edited: widget.edited,
              color: noticeForegroundColor,
              backgroundColor: noticeBackgroundColor,
              borderColor: () {
                // annimation when jumping to an event

                var pos = animationController.value;
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
