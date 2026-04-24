import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../../../../../../markdown_content.dart';
import 'html_message/html_messaged.dart';

class MessageContent extends StatelessWidget {
  const MessageContent({
    super.key,
    required this.event,
    required this.colorPatch,
  });

  final Event event;
  final Color colorPatch;

  @override
  Widget build(BuildContext context) {
    return !event.redacted && event.isRichMessage
        ? HtmlMessage(
            html: event.formattedText,
            textColor: colorPatch,
            room: event.room,
          )
        : MarkdownContent(
            color: colorPatch,
            text: event.getLocalizedBody(const MatrixDefaultLocalizations(),
                hideReply: true));
  }
}
