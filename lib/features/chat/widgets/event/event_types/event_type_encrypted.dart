import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class EventTypeEncrypted extends StatelessWidget {
  const EventTypeEncrypted({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.enhanced_encryption),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("End-To-End encryption activated"),
                  Text(
                      event.content.tryGet<String>("algorithm") ??
                          "An error happened - no algorithm given",
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
