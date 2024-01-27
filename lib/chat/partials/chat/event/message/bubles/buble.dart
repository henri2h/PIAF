import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/chat/minestrix_chat.dart';
import 'package:minestrix/chat/utils/matrix_sdk_extension/matrix_file_extension.dart';

import '../matrix_message.dart';
import 'animated_text_message_buble.dart';
import 'audio_buble.dart';
import 'file_buble.dart';
import 'image_buble.dart';
import 'text_message_bubble.dart';
import 'video_buble.dart';

class Buble extends StatefulWidget {
  const Buble(
      {super.key, required this.e, required this.state, this.replyEvent});

  final Event e;
  final MessageDisplay state;
  final Event? replyEvent;

  @override
  State<Buble> createState() => _BubleState();
}

class _BubleState extends State<Buble> with TickerProviderStateMixin {
  late Event e;

  late AnimationController _resizableController;

  StreamSubscription? onEventSelectedListener;

  @override
  void initState() {
    super.initState();
    e = widget.e;
    _resizableController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 3000,
      ),
    );
    onEventSelectedListener =
        widget.state.onEventSelectedStream?.listen((event) {
      _resizableController.reset();
      _resizableController.forward();
    });
  }

  Future<void> dowloadAttachement() async {
    final file = await e.downloadAndDecryptAttachment(
      downloadCallback: (Uri url) async {
        final file = await DefaultCacheManager().getSingleFile(url.toString());
        return await file.readAsBytes();
      },
    );
    if (mounted) {
      file.save(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool redacted = e.type == EventTypes.Redaction;

    final foregroundColor = e.sentByUser
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    final backgroundColor = e.sentByUser
        ? Theme.of(context).colorScheme.primary
        : ElevationOverlay.applySurfaceTint(
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceTint,
            20);

    final noticeBackgroundColor = e.messageType == MessageTypes.Notice
        ? ElevationOverlay.applySurfaceTint(
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceTint,
            10)
        : backgroundColor;

    final noticeForegroundColor = e.messageType == MessageTypes.Notice
        ? Theme.of(context).colorScheme.onSurface
        : foregroundColor;

    return Builder(builder: (context) {
      switch (e.messageType) {
        case MessageTypes.Image:
        case MessageTypes.Sticker:
          return ImageBuble(event: e);
        case MessageTypes.Video:
          return VideoBuble(event: e);

        case MessageTypes.Audio:
          return AudioBuble(
            event: e,
            downloadAttachement: dowloadAttachement,
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
          );
        case MessageTypes.File:
          return FileBuble(
            event: e,
            downloadAttachement: dowloadAttachement,
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
          );
        default:
          return Column(
            crossAxisAlignment: e.sentByUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (e.relationshipType == RelationshipTypes.reply)
                Transform.translate(
                  offset: const Offset(0, 4.0),
                  child: widget.replyEvent == null
                      ? Container()
                      : Opacity(
                          opacity: 0.7,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 100),
                            child: ListView(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(), // In order to prevent scrolling the replies
                              children: [
                                Align(
                                  alignment: e.sentByUser
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: TextMessageBubble(
                                      redacted: redacted,
                                      event: widget.replyEvent!,
                                      onTap: () => widget
                                          .state.onReplyEventPressed
                                          ?.call(widget.replyEvent!),
                                      color:
                                          foregroundColor, // TODO: correct color
                                      backgroundColor: backgroundColor),
                                )
                              ],
                            ),
                          ),
                        ),
                ),
              // Message annimation when jumping on specific message
              AnimatedTextMessageBuble(
                  resizableController: _resizableController,
                  redacted: redacted,
                  widget: widget.state,
                  e: e,
                  noticeForegroundColor: noticeForegroundColor,
                  noticeBackgroundColor: noticeBackgroundColor),
            ],
          );
      }
    });
  }
}
