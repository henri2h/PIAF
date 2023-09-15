import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:linkify/linkify.dart';
import 'package:matrix/matrix.dart';
import 'package:url_launcher/url_launcher.dart';

import 'extensions/code_extension.dart';
import 'extensions/custom_image_extension.dart';
import 'extensions/font_color_extension.dart';
import 'extensions/matrix_math_extension.dart';
import 'extensions/room_pill_extension.dart';
import 'extensions/spoiler_extension.dart';

class HtmlMessage extends StatelessWidget {
  final String html;
  final Room room;
  final Color textColor;

  const HtmlMessage({
    Key? key,
    required this.html,
    required this.room,
    this.textColor = Colors.black,
  }) : super(key: key);

  Future<void> _launchURL(String? url) async {
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    // riot-web is notorious for creating bad reply fallback events from invalid messages which, if
    // not handled properly, can lead to impersination. As such, we strip the entire `<mx-reply>` tags
    // here already, to prevent that from happening.
    // We do *not* do this in an AST and just with simple regex here, as riot-web tends to create
    // miss-matching tags, and this way we actually correctly identify what we want to strip and, well,
    // strip it.
    final renderHtml = html.replaceAll(
      RegExp(
        '<mx-reply>.*</mx-reply>',
        caseSensitive: false,
        multiLine: false,
        dotAll: true,
      ),
      '',
    );

    final linkifiedRenderHtml = linkify(
      renderHtml,
      options: const LinkifyOptions(humanize: false),
    )
        .map(
          (element) {
            if (element is! UrlElement ||
                element.text.contains('<') ||
                element.text.contains('>') ||
                element.text.contains('"')) {
              return element.text;
            }
            return '<a href="${element.url}">${element.text}</a>';
          },
        )
        .join('')
        .replaceAll('\n', '');

    final linkColor = textColor.withAlpha(150);

    // there is no need to pre-validate the html, as we validate it while rendering
    return Html(
      data: linkifiedRenderHtml,
      style: {
        '*': Style(
          color: textColor,
          margin: Margins.all(0),
        ),
        'a': Style(color: linkColor, textDecorationColor: linkColor),
        'blockquote': Style(
          border: Border(
            left: BorderSide(
              width: 3,
              color: textColor,
            ),
          ),
          padding: HtmlPaddings.only(left: 6, bottom: 0),
        ),
      },
      extensions: [
        RoomPillExtension(context, room),
        CodeExtension(),
        MatrixMathExtension(
          style: TextStyle(color: textColor),
        ),
        const TableHtmlExtension(),
        SpoilerExtension(textColor: textColor),
        const CustomImageExtension(),
        FontColorExtension(),
      ],
      onLinkTap: (url, _, __) => _launchURL(url),
      onlyRenderTheseTags: const {
        ...allowedHtmlTags,
        // Needed to make it work properly
        'body',
        'html',
      },
      shrinkWrap: true,
    );
  }

  /// Keep in sync with: https://spec.matrix.org/v1.6/client-server-api/#mroommessage-msgtypes
  static const Set<String> allowedHtmlTags = {
    'font',
    'del',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'blockquote',
    'p',
    'a',
    'ul',
    'ol',
    'sup',
    'sub',
    'li',
    'b',
    'i',
    'u',
    'strong',
    'em',
    'strike',
    'code',
    'hr',
    'br',
    'div',
    'table',
    'thead',
    'tbody',
    'tr',
    'th',
    'td',
    'caption',
    'pre',
    'span',
    'img',
    'details',
    'summary',
    // Not in the allowlist of the matrix spec yet but should be harmless:
    'ruby',
    'rp',
    'rt',
  };
}
