import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/chat/minestrix_chat.dart';

import 'room_list_item.dart';

class RoomListItemSlidable extends StatefulWidget {
  const RoomListItemSlidable({
    super.key,
    required this.r,
    required this.selectedRoomId,
    required this.client,
    required this.onSelection,
    required this.onLongPress,
  });

  final Room r;
  final String? selectedRoomId;
  final Client client;
  final Function(String?) onSelection;
  final VoidCallback onLongPress;

  @override
  RoomListItemSlidableState createState() => RoomListItemSlidableState();
}

class RoomListItemSlidableState extends State<RoomListItemSlidable> {
  Future<void> toggleLowPriority() async {
    await widget.r.setLowPriority(!widget.r.isLowPriority);
  }

  bool get unmuted => widget.r.pushRuleState == PushRuleState.notify;

  Future<void> toggleNotification() async {
    await widget.r.setPushRuleState(
        unmuted ? PushRuleState.mentionsOnly : PushRuleState.notify);
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) async {
              await widget.r.setFavourite(!widget.r.isFavourite);
            },
            backgroundColor: widget.r.isFavourite ? Colors.green : Colors.grey,
            foregroundColor: Colors.white,
            icon: widget.r.isFavourite ? Icons.favorite : Icons.favorite,
            label: widget.r.isFavourite ? 'Favourite' : 'Normal',
          ),
          SlidableAction(
            onPressed: (context) async {
              await toggleLowPriority();
            },
            backgroundColor:
                !widget.r.isLowPriority ? Colors.green : Colors.grey,
            foregroundColor: Colors.white,
            icon: widget.r.isLowPriority ? Icons.low_priority : Icons.list,
            label: widget.r.isLowPriority ? 'Low priority' : 'Normal priority',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
              onPressed: (context) async {
                await toggleNotification();
              },
              backgroundColor: unmuted ? Colors.green : Colors.grey,
              foregroundColor: Colors.white,
              icon: unmuted
                  ? Icons.notifications_outlined
                  : Icons.notifications_off_outlined,
              label: unmuted ? 'On' : 'Muted'),
          SlidableAction(
              onPressed: (context) async {
                await widget.r.leave();
                widget.onSelection(null);
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Leave room'),
        ],
      ),
      child: RoomListItem(
        key: Key("room_${widget.r.id}"),
        room: widget.r,
        open: widget.r.id == widget.selectedRoomId,
        client: widget.client,
        onSelection: widget.onSelection,
        onLongPress: widget.onLongPress,
      ),
    );
  }
}
