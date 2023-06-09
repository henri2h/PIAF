import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/partials/chat/event/message/html_messaged.dart';

import '../../markdown_content.dart';

class TextMessageBubble extends StatelessWidget {
  const TextMessageBubble(
      {Key? key,
      this.displayEdit = false,
      this.backgroundColor,
      this.color,
      this.borderColor,
      this.borderPadding = EdgeInsets.zero,
      required this.e,
      this.alignRight,
      required this.redacted,
      this.displaySentIndicator = false,
      this.isReply = false,
      this.edited = false})
      : super(key: key);

  final Event e;
  final Color? backgroundColor;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry borderPadding;
  final bool redacted;
  final bool displayEdit;
  final bool? alignRight;
  final bool isReply; // should we use regular chat clipper ?
  final bool edited; // display the edited indicator
  final bool displaySentIndicator;

  @override
  Widget build(BuildContext context) {
    Color colorPatch = color ?? Theme.of(context).colorScheme.onPrimary;
    final backgroundColorComputed = !e.status.isError
        ? (backgroundColor ?? Theme.of(context).colorScheme.primary)
        : Colors.red;
    return PhysicalShape(
      clipper: ChatCustomClipper(sent: e.sentByUser || isReply),
      color: borderColor ?? backgroundColorComputed,
      child: Padding(
        padding: borderPadding,
        child: PhysicalShape(
          clipper: ChatCustomClipper(sent: e.sentByUser || isReply),
          color: backgroundColorComputed,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
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
              if (e.messageType == MessageTypes.BadEncrypted) {
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
                children: [
                  !e.redacted && e.isRichMessage
                      ? HtmlMessage(
                          html: e.formattedText,
                          textColor: colorPatch,
                          room: e.room,
                        )
                      : MarkdownContent(
                          color: colorPatch,
                          text: e.getLocalizedBody(
                              const MatrixDefaultLocalizations(),
                              hideReply: true)),
                  if (edited)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, color: colorPatch, size: 12),
                        const SizedBox(width: 2),
                        Text("edited",
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  if (displaySentIndicator || e.status != EventStatus.synced)
                    Builder(builder: (context) {
                      IconData icon = Icons.error;
                      String text = "Arggg";
                      switch (e.status) {
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
                          Text(text,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: colorPatch)),
                        ],
                      );
                    })
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class ChatCustomClipper extends CustomClipper<Path> {
  // from https://github.com/KinjalDhamat312/FlutterChatBubble/blob/master/lib/clippers/chat_bubble_clipper_5.dart
  final bool sent;

  ///The radius, which creates the curved appearance of the chat widget,
  ///has a default value of 15.
  final double radius;

  /// This displays the radius for the bottom corner curve of the widget,
  /// with a default value of 2.
  final double secondRadius;

  ChatCustomClipper(
      {required this.sent, this.radius = 15, this.secondRadius = 2});

  @override
  Path getClip(Size size) {
    var path = Path();

    if (sent) {
      path.addRRect(RRect.fromLTRBR(
          0, 0, size.width, size.height, Radius.circular(radius)));
      var path2 = Path();
      path2.addRRect(RRect.fromLTRBAndCorners(0, 0, radius, radius,
          bottomRight: Radius.circular(secondRadius)));
      path.addPath(path2, Offset(size.width - radius, size.height - radius));
    } else {
      path.addRRect(RRect.fromLTRBR(
          0, 0, size.width, size.height, Radius.circular(radius)));
      var path2 = Path();
      path2.addRRect(RRect.fromLTRBAndCorners(0, 0, radius, radius,
          topLeft: Radius.circular(secondRadius)));
      path.addPath(path2, const Offset(0, 0));
    }

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
