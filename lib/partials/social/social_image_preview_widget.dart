import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../event/matrix_image.dart';

class SocialImagePreviewWidget extends StatelessWidget {
  final Event e;
  const SocialImagePreviewWidget({super.key, required this.e});

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
