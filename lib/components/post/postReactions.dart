
import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTheme.dart';

class PostReactions extends StatelessWidget {
  final Event event;
  final Set<Event> reactions;
  const PostReactions({Key key, @required this.event, @required this.reactions})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    Map<String, int> keys = new Map<String, int>();
    for (Event revent in reactions) {
      String key = revent.content['m.relates_to']['key'];
      keys.update(key, (value) => value + 1, ifAbsent: () => 1);
    }
    return Row(
      children: [
        for (MapEntry<String, int> key in keys.entries)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ReactionItemWidget(
              Row(children: [
                Text(key.key),
                SizedBox(width: 10),
                Text(key.value.toString())
              ]),
            ),
          ),
      ],
    );
  }
}

class ReactionItemWidget extends StatelessWidget {
  final Widget child;
  const ReactionItemWidget(
    this.child, {
    Key key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1.6),
      decoration: BoxDecoration(
        gradient: MinesTrixTheme.buttonGradient,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              color: Colors.white,
              borderRadius: BorderRadius.circular(32)),
          child: child),
    );
  }
}
