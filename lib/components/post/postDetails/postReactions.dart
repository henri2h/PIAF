import 'package:matrix/matrix.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTheme.dart';

class PostReactions extends StatelessWidget {
  final Event event;
  final Set<Event> reactions;
  const PostReactions({Key? key, required this.event, required this.reactions})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    Map<String?, int> keys = new Map<String?, int>();
    for (Event revent in reactions) {
      String? key = revent.content['m.relates_to']['key'];
      keys.update(key, (value) => value + 1, ifAbsent: () => 1);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        for (MapEntry<String?, int> key in keys.entries)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(children: [
              Text(key.key!),
              SizedBox(width: 2),
              Text(key.value.toString())
            ]),
          ),
      ],
    );
  }
}
