import 'package:flutter/material.dart';

import '../room_list_items/room_list_item.dart';

class PlaceholderList extends StatelessWidget {
  const PlaceholderList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
        key: const Key("placeholder_list"),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int i) => const RoomListItemShimmer(),
          childCount: 5,
        ));
  }
}
