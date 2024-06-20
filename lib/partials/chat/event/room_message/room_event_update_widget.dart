import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class RoomEventUpdateWidget extends StatelessWidget {
  const RoomEventUpdateWidget(
    this.event, {
    super.key,
  });

  final Event event;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: event.calcLocalizedBody(const MatrixDefaultLocalizations()),
        builder: (context, snap) {
          IconData icon = Icons.device_unknown;

          if (event.type == EventTypes.RoomMember) {
            icon = Icons.person;
            switch (event.roomMemberChangeType) {
              case RoomMemberChangeType.avatar:
                icon = Icons.camera;
                break;
              case RoomMemberChangeType.displayname:
                icon = Icons.edit;
                break;
              case RoomMemberChangeType.join:
                icon = Icons.waving_hand;
                break;
              case RoomMemberChangeType.acceptInvite:
                icon = Icons.waving_hand;
                break;
              case RoomMemberChangeType.leave:
                icon = Icons.logout;
                break;
              case RoomMemberChangeType.kick:
                icon = Icons.person_remove;
                break;
              case RoomMemberChangeType.invite:
                icon = Icons.person_add;
                break;
              default:
                break;
            }
          } else if (event.type == EventTypes.RoomCreate) {
            icon = Icons.create_new_folder;
          } else if (event.type == EventTypes.HistoryVisibility) {
            icon = Icons.visibility;
          } else if (event.type == EventTypes.GuestAccess) {
            icon = Icons.public;
          } else if (event.type == EventTypes.RoomName) {
            icon = Icons.edit;
          } else if (event.type == EventTypes.RoomTopic) {
            icon = Icons.edit;
          }

          return Padding(
            // size: 40 + padding left of 10
            padding: const EdgeInsets.only(left: 50.0, top: 8, bottom: 8),
            child: Row(
              children: [
                Icon(icon,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    size: Theme.of(context).textTheme.bodySmall?.fontSize),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: Text(snap.data ?? '',
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
          );
        });
  }
}
