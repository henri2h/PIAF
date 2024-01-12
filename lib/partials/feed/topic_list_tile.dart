import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:matrix/matrix.dart';
import 'package:url_launcher/url_launcher.dart';

class TopicListTile extends StatelessWidget {
  const TopicListTile({
    super.key,
    required this.room,
  });

  final Room room;

  @override
  Widget build(BuildContext context) {
    if (room.topic.isEmpty) {
      return Container();
    }
    return TopicBody(room: room);
  }
}

class TopicBody extends StatelessWidget {
  const TopicBody({
    super.key,
    required this.room,
  });

  final Room room;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
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
        });
  }
}
