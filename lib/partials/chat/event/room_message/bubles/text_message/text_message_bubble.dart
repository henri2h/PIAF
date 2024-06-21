import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/chat/event/event_widget.dart';
import 'package:piaf/partials/minestrix_chat.dart';

import 'bad_encrypted.dart';
import 'message_content.dart';
import 'message_status.dart';

class TextMessageBubble extends StatelessWidget {
  const TextMessageBubble(
      {super.key,
      this.displayEdit = false,
      this.backgroundColor,
      this.color,
      this.borderColor,
      required this.event,
      required this.redacted,
      this.showSentIndicator = false,
      this.edited = false,
      this.onTap,
      this.showMessageSentTime = true,
      required this.showSenderName,
      this.isReply = false,
      this.eventContext});

  final Event event;
  final bool isReply;
  final Color? backgroundColor;
  final Color? color;
  final Color? borderColor;
  final bool redacted;
  final bool displayEdit;
  final bool edited; // display the edited indicator
  final bool showSentIndicator;
  final VoidCallback? onTap;
  final bool showMessageSentTime;
  final bool showSenderName;
  final EventWidget? eventContext;

  @override
  Widget build(BuildContext context) {
    Color colorPatch = color ?? Theme.of(context).colorScheme.onPrimary;
    final backgroundColorComputed = !event.status.isError
        ? (backgroundColor ?? Theme.of(context).colorScheme.primary)
        : Colors.red;

    // Text theme for the time and send status text
    final textTheme = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: colorPatch.withOpacity(0.7), fontSize: 10);

    // Determine if we should have rounded borders in case of the
    // previous message has also been sent by the same user.
    final samePrev = eventContext?.evContext.isPreEventFromSameId ?? false;
    final sameNext = eventContext?.evContext.isNextEventFromSameId ?? false;
    final sentByUser = eventContext?.evContext.sentByUser ?? false;
    final borderRadius = BorderRadius.only(
        topLeft:
            samePrev && !sentByUser ? Radius.zero : const Radius.circular(8),
        topRight:
            samePrev && sentByUser ? Radius.zero : const Radius.circular(8),
        bottomLeft:
            sameNext && !sentByUser ? Radius.zero : const Radius.circular(8),
        bottomRight:
            sameNext && sentByUser ? Radius.zero : const Radius.circular(8));

    return Card(
      margin: EdgeInsets.zero,
      color: backgroundColorComputed,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: Builder(builder: (context) {
            if (redacted) {
              return Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.delete_forever, color: colorPatch),
                const SizedBox(width: 10),
                Flexible(
                    child: Text("Message redacted",
                        style: TextStyle(color: colorPatch)))
              ]);
            }
            if (event.messageType == MessageTypes.BadEncrypted) {
              return BadEncrypted(colorPatch: colorPatch);
            }

            Widget messageView =
                MessageContent(event: event, colorPatch: colorPatch);

            if (isReply) {
              /*messageView = ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: ListView(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(), // In order to prevent scrolling the replies
                      children: [messageView]));*/
              // TODO: Find a way to support markdown or html messages also in reply
              messageView = Text(
                event.calcLocalizedBodyFallback(
                    const MatrixDefaultLocalizations(),
                    hideReply: true),
                maxLines: 2,
                overflow: TextOverflow.fade,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showSenderName && !event.sentByUser)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2.0),
                          child: Text(
                              event.senderFromMemoryOrFallback
                                  .calcDisplayname(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                      color: colorPatch,
                                      fontWeight: FontWeight.w600)),
                        ),
                      messageView,
                    ],
                  ),
                ),
                if (showMessageSentTime ||
                    edited ||
                    showSentIndicator ||
                    event.status != EventStatus.synced)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0, bottom: 2),
                    child: MessageStatus(
                        edited: edited,
                        colorPatch: colorPatch,
                        textTheme: textTheme,
                        displayTime: showMessageSentTime,
                        event: event,
                        displaySentIndicator: showSentIndicator),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
