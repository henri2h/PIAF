import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../room_list_items/room_list_item_presence.dart';

class PresenceList extends StatelessWidget {
  const PresenceList({
    super.key,
    required this.presences,
    required this.client,
    required this.onSelection,
  });

  final List<CachedPresence>? presences;
  final Client client;
  final Function(String? p1) onSelection;

  @override
  Widget build(BuildContext context) {
    return SliverList(
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
      final presence = presences![index];
      return RoomListItemPresence(
          client: client,
          presence: presence,
          onTap: () {
            final room = client.getDirectChatFromUserId(presence.userid);
            onSelection(room ?? presence.userid);
          });
    }, childCount: presences!.length));
  }
}
