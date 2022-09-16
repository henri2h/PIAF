import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/dialogs/custom_dialogs.dart';
import 'package:url_launcher/url_launcher.dart';

class TopicListTile extends StatelessWidget {
  const TopicListTile({
    Key? key,
    required this.room,
  }) : super(key: key);

  final Room room;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: ListTile(
              title: room.topic.isEmpty
                  ? const Text("Set topic")
                  : MarkdownBody(
                      data: room.topic,
                      onTapLink: (text, href, title) async {
                        if (href != null) {
                          final url = Uri.parse(href);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          } else {
                            throw 'Could not launch $href';
                          }
                        }
                      }),
              leading: const Icon(Icons.topic),
              onTap: !room.canSendDefaultStates
                  ? null
                  : () async {
                      String? topic = await CustomDialogs.showCustomTextDialog(
                        context,
                        title: "Set the event topic",
                        helpText: "Event topic",
                        initialText: room.topic,
                      );
                      if (topic != null) {
                        await room.setDescription(topic);
                      }
                    }),
        ),
      ],
    );
  }
}
