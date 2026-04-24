import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:matrix/matrix.dart';

class MatrixMathExtension extends HtmlExtension {
  final TextStyle? style;

  MatrixMathExtension({this.style});
  @override
  Set<String> get supportedTags => {'div'};

  @override
  bool matches(ExtensionContext context) {
    if (context.elementName != 'div') return false;
    final mathData = context.element?.attributes['data-mx-maths'];
    return mathData != null;
  }

  @override
  InlineSpan build(ExtensionContext context) {
    final data = context.element?.attributes['data-mx-maths'] ?? '';
    return WidgetSpan(
      child: Math.tex(
        data,
        textStyle: style,
        onErrorFallback: (e) {
          Logs().d('Flutter math parse error', e);
          return Text(
            data,
            style: style,
          );
        },
      ),
    );
  }
}
