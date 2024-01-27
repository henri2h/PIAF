import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class CustomImageExtension extends HtmlExtension {
  final double defaultDimension;

  const CustomImageExtension({this.defaultDimension = 64});

  @override
  Set<String> get supportedTags => {'img'};

  @override
  InlineSpan build(ExtensionContext context) {
    final mxcUrl = Uri.tryParse(context.attributes['src'] ?? '');
    if (mxcUrl == null || mxcUrl.scheme != 'mxc') {
      return TextSpan(text: context.attributes['alt']);
    }

    //final width = double.tryParse(context.attributes['width'] ?? '');
    //final height = double.tryParse(context.attributes['height'] ?? '');
    return WidgetSpan(
        child: Text("Displaying text is not supported yet. mxc: $mxcUrl"));
  }
}
