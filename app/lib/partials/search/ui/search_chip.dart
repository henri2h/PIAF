import 'package:flutter/material.dart';

import '../../../models/search/search_mode.dart';

class SearchChip extends StatelessWidget {
  const SearchChip({
    super.key,
    required this.onPressed,
    required this.mode,
  });

  final void Function(SearchMode p1) onPressed;
  final SearchMode mode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ActionChip(
        avatar: Icon(mode.icon),
        label: Text(mode.text),
        onPressed: () {
          onPressed(mode);
        },
      ),
    );
  }
}
