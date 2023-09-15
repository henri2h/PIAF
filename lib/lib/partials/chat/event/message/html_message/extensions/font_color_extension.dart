
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class FontColorExtension extends HtmlExtension {
  static const String colorAttribute = 'color';
  static const String mxColorAttribute = 'data-mx-color';
  static const String bgColorAttribute = 'data-mx-bg-color';

  @override
  Set<String> get supportedTags => {'font', 'span'};

  @override
  bool matches(ExtensionContext context) {
    if (!supportedTags.contains(context.elementName)) return false;
    return context.element?.attributes.keys.any(
          {
            colorAttribute,
            mxColorAttribute,
            bgColorAttribute,
          }.contains,
        ) ??
        false;
  }

  Color? hexToColor(String? hexCode) {
    if (hexCode == null) return null;
    if (hexCode.startsWith('#')) hexCode = hexCode.substring(1);
    if (hexCode.length == 6) hexCode = 'FF$hexCode';
    final colorValue = int.tryParse(hexCode, radix: 16);
    return colorValue == null ? null : Color(colorValue);
  }

  @override
  InlineSpan build(
    ExtensionContext context,
  ) {
    final colorText = context.element?.attributes[colorAttribute] ??
        context.element?.attributes[mxColorAttribute];
    final bgColor = context.element?.attributes[bgColorAttribute];
    return TextSpan(
      style: TextStyle(
        color: hexToColor(colorText),
        backgroundColor: hexToColor(bgColor),
      ),
      text: context.innerHtml,
    );
  }
}
