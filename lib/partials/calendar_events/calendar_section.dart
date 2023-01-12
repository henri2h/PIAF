import 'package:flutter/material.dart';

import '../components/minestrix/minestrix_title.dart';

class CreateCalendarSection extends StatelessWidget {
  const CreateCalendarSection({
    Key? key,
    required this.text,
    required this.child,
  }) : super(key: key);

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
