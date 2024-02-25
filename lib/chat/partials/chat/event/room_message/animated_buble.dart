import 'dart:async';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../event_widget.dart';
import 'bubles/animated_text_message_buble.dart';

class AnnimatedBuble extends StatefulWidget {
  const AnnimatedBuble(
      {super.key,
      required this.event,
      required this.noticeForegroundColor,
      required this.noticeBackgroundColor,
      required this.state});

  final Event event;
  final Color noticeBackgroundColor;
  final Color noticeForegroundColor;

  final EventWidget state;

  @override
  State<AnnimatedBuble> createState() => _AnnimatedBubleState();
}

class _AnnimatedBubleState extends State<AnnimatedBuble>
    with TickerProviderStateMixin {
  late AnimationController animationController;

  StreamSubscription? onEventSelectedListener;

  @override
  void initState() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 3000,
      ),
    );
    onEventSelectedListener =
        widget.state.onEventSelectedStream?.listen((event) {
      animationController.reset();
      animationController.forward();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool redacted = widget.event.type == EventTypes.Redaction;

    return // Message annimation when jumping on specific message
        AnimatedTextMessageBuble(
            resizableController: animationController,
            redacted: redacted,
            widget: widget.state,
            e: widget.event,
            noticeForegroundColor: widget.noticeForegroundColor,
            noticeBackgroundColor: widget.noticeBackgroundColor);
  }
}
