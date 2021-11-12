import 'package:matrix/matrix.dart';
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (MapEntry<String, int> key in keys.entries)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(children: [
              Text(key.key),
              SizedBox(width: 2),
              Text(key.value.toString())
            ]),
          ),
        SizedBox(width: 10),
        Flexible(child: Text("React"))
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
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        gradient: MinesTrixTheme.buttonGradient,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              color: Colors.white,
              borderRadius: BorderRadius.circular(32)),
          child: child),
    );
  }
}
