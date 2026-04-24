import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/minestrix_chat.dart';
import 'package:piaf/utils/matrix_sdk_extension/matrix_file_extension.dart';

import '../../event_widget.dart';
import 'bubles/audio_buble.dart';
import 'bubles/file_buble.dart';
import 'bubles/image_buble.dart';
import 'bubles/text_message_bubble.dart';
import 'bubles/video_buble.dart';

class Buble extends StatefulWidget {
  const Buble({super.key, required this.state, this.replyEvent});

  final EventWidget state;
  final Event? replyEvent;

  @override
  State<Buble> createState() => _BubleState();
}

class _BubleState extends State<Buble> {
  Future<void> dowloadAttachement() async {
    final file = await widget.state.ctx.event.downloadAndDecryptAttachment(
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
    final event = widget.state.ctx.event;
    bool redacted = event.type == EventTypes.Redaction;

    final foregroundColor = event.sentByUser
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSecondary;

    final backgroundColor = event.sentByUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;

    final noticeBackgroundColor = event.messageType == MessageTypes.Notice
        ? ElevationOverlay.applySurfaceTint(
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceTint,
            10)
        : backgroundColor;

    final noticeForegroundColor = event.messageType == MessageTypes.Notice
        ? Theme.of(context).colorScheme.onSurface
        : foregroundColor;

    return Column(
      crossAxisAlignment:
          event.sentByUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (widget.replyEvent != null)
          Transform.translate(
            offset: const Offset(0, 4.0),
            child: TextMessageBubble(
                redacted: redacted,
                isReply: true,
                event: widget.replyEvent!,
                showMessageSentTime: false,
                // don't show sender name in direct chat
                showSenderName: !widget.state.ctx.isDirectChat,
                onTap: () =>
                    widget.state.onReplyEventPressed?.call(widget.replyEvent!),
                color: widget.replyEvent!.sentByUser
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSecondaryContainer,
                backgroundColor: widget.replyEvent!.sentByUser
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.secondaryContainer),
          ),
        Builder(builder: (context) {
          switch (event.messageType) {
            case MessageTypes.Image:
            case MessageTypes.Sticker:
              return ImageBuble(event: event);
            case MessageTypes.Video:
              return VideoBuble(event: event);

            case MessageTypes.Audio:
              return AudioBuble(
                event: event,
                downloadAttachement: dowloadAttachement,
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
              );
            case MessageTypes.File:
              return FileBuble(
                event: event,
                downloadAttachement: dowloadAttachement,
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
              );
            default:
              return // TODO: Add back annimation builder with the Animated Text Message Class
                  TextMessageBubble(
                event: event,
                eventContext: widget.state,
                redacted: redacted,
                showSentIndicator:
                    widget.state.ctx.isLastMessage && event.sentByUser,
                edited: widget.state.ctx.edited,
                backgroundColor: noticeBackgroundColor,
                color: noticeForegroundColor,
                showSenderName: widget.state.displayName,
              );
          }
        }),
      ],
    );
  }
}
