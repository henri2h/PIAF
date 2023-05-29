import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../event/matrix_image.dart';

class SocialImagePreviewWidget extends StatelessWidget {
  final Event e;
  const SocialImagePreviewWidget({Key? key, required this.e}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MImageViewer(
        event: e,
        fit: BoxFit.cover,
      ),
    );
  }
}
