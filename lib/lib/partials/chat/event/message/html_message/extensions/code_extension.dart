import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_html/flutter_html.dart';

class CodeExtension extends HtmlExtension {
  @override
  Set<String> get supportedTags => {'code'};

  @override
  InlineSpan build(ExtensionContext context) => WidgetSpan(
        child: Material(
          clipBehavior: Clip.hardEdge,
          borderRadius: BorderRadius.circular(4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HighlightView(
              context.element?.text ?? '',
              language: context.element?.className
                      .split(' ')
                      .singleWhereOrNull(
                        (className) => className.startsWith('language-'),
                      )
                      ?.split('language-')
                      .last ??
                  'md',
              padding: EdgeInsets.symmetric(
                horizontal: 6,
                vertical: context.element?.parent?.localName == 'pre' ? 6 : 0,
              ),
            ),
          ),
        ),
      );
}
