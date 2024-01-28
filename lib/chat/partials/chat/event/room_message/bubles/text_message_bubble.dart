import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/chat/partials/chat/event/room_message/html_message/html_messaged.dart';

import '../../../markdown_content.dart';

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
              return Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.lock_clock, color: colorPatch),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Message encrypted",
                          style: TextStyle(color: colorPatch)),
                      Text("Waiting for encryption key, it may take a while",
                          style: TextStyle(color: colorPatch, fontSize: 12))
                    ],
                  ),
                )
              ]);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: !event.redacted && event.isRichMessage
                      ? HtmlMessage(
                          html: event.formattedText,
                          textColor: colorPatch,
                          room: event.room,
                        )
                      : MarkdownContent(
                          color: colorPatch,
                          text: event.getLocalizedBody(
                              const MatrixDefaultLocalizations(),
                              hideReply: true)),
                ),
                if (displayTime ||
                    edited ||
                    displaySentIndicator ||
                    event.status != EventStatus.synced)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (edited) Icon(Icons.edit, color: colorPatch, size: 12),
                      if (edited) const SizedBox(width: 2),
                      if (edited) Text("edited", style: textTheme),
                      if (displayTime)
                        Text(DateFormat.Hm().format(event.originServerTs),
                            style: textTheme),
                      if (displaySentIndicator ||
                          event.status != EventStatus.synced)
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Builder(builder: (context) {
                            IconData icon = Icons.error;
                            String text = "Arggg";
                            switch (event.status) {
                              case EventStatus.removed:
                                break;
                              case EventStatus.error:
                                // TODO: Handle this case.
                                break;
                              case EventStatus.sending:
                                icon = Icons.flight_takeoff;
                                text = "Sending";
                                break;
                              case EventStatus.sent:
                                icon = Icons.check_circle_outline;
                                text = "Sent";
                                break;
                              case EventStatus.synced:
                                text = "Synced";
                                icon = Icons.check_circle;
                                break;
                              case EventStatus.roomState:
                                // TODO: Handle this case.
                                break;
                            }
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, color: colorPatch, size: 12),
                                const SizedBox(width: 2),
                                Text(text, style: textTheme),
                              ],
                            );
                          }),
                        )
                    ],
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
