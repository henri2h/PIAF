import 'dart:math';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../../../../../../../partials/matrix/event/matrix_image.dart';

class ImageBuble extends StatelessWidget {
  const ImageBuble({super.key, required this.event});
  final Event event;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: min<double>(MediaQuery.of(context).size.width * 0.6, 300),
          maxHeight: min<double>(MediaQuery.of(context).size.height * 0.4, 400),
        ),
        child: MImageViewer(event: event));
  }
}
