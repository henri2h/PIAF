import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/chat/minestrix_chat.dart';

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
      required this.showSenderName});

  final Event event;
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

    return Card(
      margin: EdgeInsets.zero,
      color: backgroundColorComputed,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
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

            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(4.0),
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
                      MessageContent(event: event, colorPatch: colorPatch),
                    ],
                  ),
                ),
                if (showMessageSentTime ||
                    edited ||
                    showSentIndicator ||
                    event.status != EventStatus.synced)
                  MessageStatus(
                      edited: edited,
                      colorPatch: colorPatch,
                      textTheme: textTheme,
                      displayTime: showMessageSentTime,
                      event: event,
                      displaySentIndicator: showSentIndicator),
              ],
            );
          }),
        ),
      ),
    );
  }
}
