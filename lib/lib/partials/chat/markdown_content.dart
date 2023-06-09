import 'package:flutter/material.dart';

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownContent extends StatelessWidget {
  const MarkdownContent({Key? key, required this.text, required this.color})
      : super(key: key);
  final Color color;

  final String text;

  Future<void> _launchURL(Uri url) async {
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
        data: text,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .p!
                .copyWith(color: color),
            a: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .a!
                .copyWith(color: color, fontWeight: FontWeight.bold),
            h1: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .h1!
                .copyWith(color: color),
            h2: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .h2!
                .copyWith(color: color),
            h3: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .h3!
                .copyWith(color: color),
            h4: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .h4!
                .copyWith(color: color),
            listBullet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .listBullet!
                .copyWith(color: color),
            blockquotePadding: const EdgeInsets.only(left: 14),
            blockquoteDecoration: const BoxDecoration(
                border:
                    Border(left: BorderSide(color: Colors.white70, width: 4)))),
        onTapLink: (text, href, title) async {
          if (href != null) {
            await _launchURL(Uri.parse(href));
          }
        });
  }
}
