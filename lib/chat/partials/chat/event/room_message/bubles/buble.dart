import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/chat/minestrix_chat.dart';
import 'package:minestrix/chat/utils/matrix_sdk_extension/matrix_file_extension.dart';

import '../../event_widget.dart';
import 'audio_buble.dart';
import 'file_buble.dart';
import 'image_buble.dart';
import 'text_message/text_message_bubble.dart';
import 'video_buble.dart';

class Buble extends StatefulWidget {
  const Buble(
      {super.key, required this.e, required this.state, this.replyEvent});

  final Event e;
  final EventWidget state;
  final Event? replyEvent;

  @override
  State<Buble> createState() => _BubleState();
}

class _BubleState extends State<Buble> {
  Future<void> dowloadAttachement() async {
    final file = await widget.e.downloadAndDecryptAttachment(
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
    bool redacted = widget.e.type == EventTypes.Redaction;

    final foregroundColor = widget.e.sentByUser
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    final backgroundColor = widget.e.sentByUser
        ? Theme.of(context).colorScheme.primary
        : ElevationOverlay.applySurfaceTint(
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceTint,
            20);

    final noticeBackgroundColor = widget.e.messageType == MessageTypes.Notice
        ? ElevationOverlay.applySurfaceTint(
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceTint,
            10)
        : backgroundColor;

    final noticeForegroundColor = widget.e.messageType == MessageTypes.Notice
        ? Theme.of(context).colorScheme.onSurface
        : foregroundColor;

    return Builder(builder: (context) {
      switch (widget.e.messageType) {
        case MessageTypes.Image:
        case MessageTypes.Sticker:
          return ImageBuble(event: widget.e);
        case MessageTypes.Video:
          return VideoBuble(event: widget.e);

        case MessageTypes.Audio:
          return AudioBuble(
            event: widget.e,
            downloadAttachement: dowloadAttachement,
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
          );
        case MessageTypes.File:
          return FileBuble(
            event: widget.e,
            downloadAttachement: dowloadAttachement,
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
          );
        default:
          return Column(
            crossAxisAlignment: widget.e.sentByUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (widget.e.relationshipType == RelationshipTypes.reply)
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
                                  alignment: widget.e.sentByUser
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: TextMessageBubble(
                                      redacted: redacted,
                                      event: widget.replyEvent!,
                                      displayTime: false,
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
              // TODO: Add back annimation builder with the Animated Text Message Class
              TextMessageBubble(
                  event: widget.e,
                  redacted: redacted,
                  displaySentIndicator:
                      widget.state.isLastMessage && widget.e.sentByUser,
                  edited: widget.state.edited,
                  backgroundColor: noticeBackgroundColor,
                  color: noticeForegroundColor)
            ],
          );
      }
    });
  }
}
