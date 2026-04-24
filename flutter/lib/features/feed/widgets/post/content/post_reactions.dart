import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

class PostReactions extends StatelessWidget {
  final Event event;
  final Set<Event> reactions;
  const PostReactions(
      {super.key, required this.event, required this.reactions});
  @override
  Widget build(BuildContext context) {
    Map<String?, int> keys = <String?, int>{};
    for (Event revent in reactions) {
      String? key = revent.content
          .tryGetMap<String, dynamic>('m.relates_to')
          ?.tryGet<String>('key');
      keys.update(key, (value) => value + 1, ifAbsent: () => 1);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        for (MapEntry<String?, int> key in keys.entries)
          if (key.key != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(children: [
                Text(key.key!),
                const SizedBox(width: 2),
                Text(key.value.toString())
              ]),
            ),
      ],
    );
  }
}
