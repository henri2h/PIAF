import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class SpoilerExtension extends HtmlExtension {
  final Color textColor;

  const SpoilerExtension({required this.textColor});

  @override
  Set<String> get supportedTags => {'span'};

  static const String customDataAttribute = 'data-mx-spoiler';

  @override
  bool matches(ExtensionContext context) {
    if (context.elementName != 'span') return false;
    return context.element?.attributes.containsKey(customDataAttribute) ??
        false;
  }

  @override
  InlineSpan build(ExtensionContext context) {
    var obscure = true;
    final children = context.inlineSpanChildren;
    return WidgetSpan(
      child: StatefulBuilder(
        builder: (context, setState) {
          return InkWell(
            onTap: () => setState(() {
              obscure = !obscure;
            }),
            child: RichText(
              text: TextSpan(
                style: obscure ? TextStyle(backgroundColor: textColor) : null,
                children: children,
              ),
            ),
          );
        },
      ),
    );
  }
}
