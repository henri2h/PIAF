import 'package:flutter/material.dart';

import '../../../partials/typo/titles.dart';

class CreateCalendarSection extends StatelessWidget {
  const CreateCalendarSection({
    super.key,
    required this.text,
    required this.child,
  });

  final String text;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          H3Title(
            text,
          ),
          const SizedBox(
            height: 8,
          ),
          child
        ],
      ),
    );
  }
}
