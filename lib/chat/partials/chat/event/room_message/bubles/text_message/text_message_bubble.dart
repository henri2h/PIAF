import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

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
      this.displaySentIndicator = false,
      this.edited = false,
      this.onTap,
      this.displayTime = true});

  final Event event;
  final Color? backgroundColor;
  final Color? color;
  final Color? borderColor;
  final bool redacted;
  final bool displayEdit;
  final bool edited; // display the edited indicator
  final bool displaySentIndicator;
  final VoidCallback? onTap;
  final bool displayTime;

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
                MessageContent(event: event, colorPatch: colorPatch),
                if (displayTime ||
                    edited ||
                    displaySentIndicator ||
                    event.status != EventStatus.synced)
                  MessageStatus(
                      edited: edited,
                      colorPatch: colorPatch,
                      textTheme: textTheme,
                      displayTime: displayTime,
                      event: event,
                      displaySentIndicator: displaySentIndicator),
              ],
            );
          }),
        ),
      ),
    );
  }
}
