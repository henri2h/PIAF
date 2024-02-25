import 'package:flutter/material.dart';

class EventReactions extends StatelessWidget {
  const EventReactions(
      {super.key, required this.displayReactionDialog, required this.keys});

  final void Function(BuildContext context) displayReactionDialog;
  final Map<String?, int> keys;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (MapEntry<String?, int> key in keys.entries)
            Material(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(1.6),
                child: Material(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: GestureDetector(
                        onLongPress: () => displayReactionDialog(context),
                        child: MaterialButton(
                            minWidth: 8,
                            height: 0,
                            padding: const EdgeInsets.only(),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onPressed: () => displayReactionDialog(context),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(key.key!,
                                      style: const TextStyle(fontSize: 12)),
                                  const SizedBox(width: 2),
                                  Text(key.value.toString(),
                                      style:
                                          Theme.of(context).textTheme.bodySmall)
                                ]))),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
