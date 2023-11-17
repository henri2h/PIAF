import 'package:flutter/material.dart';

import '../search_mode.dart';
import 'search_chip.dart';

class SearchBadges extends StatelessWidget {
  const SearchBadges({
    super.key,
    required this.onSearchModeSelected,
  });

  final void Function(SearchMode) onSearchModeSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Search for", style: Theme.of(context).textTheme.titleLarge),
          SearchChip(mode: SearchMode.user, onPressed: onSearchModeSelected),
          SearchChip(
              mode: SearchMode.publicRoom, onPressed: onSearchModeSelected),
        ],
      ),
    );
  }
}
