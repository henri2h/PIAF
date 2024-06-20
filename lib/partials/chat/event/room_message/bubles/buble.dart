import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/minestrix_chat.dart';
import 'package:piaf/partials/utils/matrix_sdk_extension/matrix_file_extension.dart';

import '../../event_widget.dart';
import 'audio_buble.dart';
import 'file_buble.dart';
import 'image_buble.dart';
import 'text_message/text_message_bubble.dart';
import 'video_buble.dart';

class Buble extends StatefulWidget {
  const Buble(
      {super.key,
      required this.e,
      required this.eventWidgetState,
      this.replyEvent});

  final Event e;
  final EventWidget eventWidgetState;
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
        : Theme.of(context).colorScheme.onSecondary;

    final backgroundColor = widget.e.sentByUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;

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
                      : ConstrainedBox(
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
                                    showMessageSentTime: false,
                                    // don't show sender name in direct chat
                                    showSenderName:
                                        !widget.eventWidgetState.isDirectChat,
                                    onTap: () => widget
                                        .eventWidgetState.onReplyEventPressed
                                        ?.call(widget.replyEvent!),
                                    color: widget.replyEvent!.sentByUser
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer,
                                    backgroundColor:
                                        widget.replyEvent!.sentByUser
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primaryContainer
                                            : Theme.of(context)
                                                .colorScheme
                                                .secondaryContainer),
                              )
                            ],
                          ),
                        ),
                ),
              // TODO: Add back annimation builder with the Animated Text Message Class
              TextMessageBubble(
                event: widget.e,
                eventContext: widget.eventWidgetState,
                redacted: redacted,
                showSentIndicator: widget.eventWidgetState.isLastMessage &&
                    widget.e.sentByUser,
                edited: widget.eventWidgetState.edited,
                backgroundColor: noticeBackgroundColor,
                color: noticeForegroundColor,
                showSenderName: widget.eventWidgetState.displayName,
              )
            ],
          );
      }
    });
  }
}
