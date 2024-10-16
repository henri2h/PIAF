import 'package:flutter/material.dart';

class NoRoomList extends StatelessWidget {
  const NoRoomList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
        key: const Key("placeholder_list"),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int i) => Center(
              child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 80.0),
            child: Column(
              children: [
                const Icon(Icons.message_outlined, size: 60),
                const SizedBox(
                  height: 30,
                ),
                Text(
                  "No rooms",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          )),
          childCount: 1,
        ));
  }
}
