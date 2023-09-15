
import 'package:flutter/material.dart';
import 'package:infinite_list/infinite_list.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/utils/extensions/datetime.dart';

import '../../dialogs/adaptative_dialogs.dart';
import '../event/message/matrix_message.dart';
import '../event/read_receipts/read_receipt_item.dart';
import '../event/read_receipts/read_receipts_list.dart';

class ItemBuilder extends StatelessWidget {
  const ItemBuilder(
      {Key? key,
      this.displayAvatar = false,
      this.displayName = false,
      this.displayTime = false,
      this.displayPadding = false,
      required this.room,
      required this.t,
      required this.filteredEvents,
      required this.onReact,
      required this.position,
      required this.i,
      required this.onReplyEventPressed,
      required this.onReply,
      this.onSelected,
      this.fullyReadEventId})
      : super(key: key);

  final Room room;
  final Timeline t;
  final List<Event> filteredEvents;
  final bool displayAvatar;
  final bool displayName;
  final bool displayTime;
  final bool displayPadding;
  final void Function(Offset, Event) onReact;
  final ItemPositions position;
  final int i;
  final void Function(Event) onReplyEventPressed;
  final void Function(Event) onReply;
  final Stream<String>? onSelected;
  final String? fullyReadEventId;

  @override
  Widget build(BuildContext context) {
    // local overrides
    bool displayName = this.displayName;
    bool displayTime = this.displayTime;
    bool displayPadding = this.displayPadding;
    bool displayAvatar = this.displayAvatar;

    if (position != ItemPositions.item) return Container();
    Event event = filteredEvents[i];

    Set<Event> reactions =
        event.aggregatedEvents(t, RelationshipTypes.reaction);

    final prevEvent =
        i < filteredEvents.length - 1 ? filteredEvents[i + 1] : null;
    final nextEvent = i > 0 ? filteredEvents[i - 1] : null;

    if (prevEvent != null) {
      // check if the preceding message was sent by the same user
      // TODO : check dates
      if (event.type == EventTypes.Message) {
        if (event.senderId != prevEvent.senderId) {
          displayName = !room.isDirectChat;
          displayPadding = true;
        }

        if (event.originServerTs
                .difference(prevEvent.originServerTs)
                .inHours
                .abs() >
            2) {
          displayTime = true;
        }
      }

      if ((prevEvent.type == EventTypes.Message &&
              event.type != EventTypes.Message) ||
          (event.type == EventTypes.Message &&
              event.type != EventTypes.Message)) {
        displayPadding = true;
      }
    }

    if (nextEvent?.senderId != event.senderId ||
        nextEvent?.type != EventTypes.Message) {
      displayAvatar = true;
    }

    if (event.status.isError) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: MaterialButton(
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.restart_alt),
          ),
          onPressed: () async {
            await event.sendAgain();
          },
        ),
      );
    }
    final oldEvent = event;
    event = event.getDisplayEvent(t);
    final edited = event.eventId != oldEvent.eventId;

    if (displayTime) {
      // in case of we should display the time, we take care of the padding ourself
      displayPadding = false;
    }

    return Column(
      children: [
        if (displayTime)
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 14),
            child: Text(event.originServerTs.timeSince,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ),
        MessageDisplay(
            key: Key("ed_${event.eventId}"),
            event: event,
            timeline: t,
            reactions: reactions,
            client: room.client,
            isLastMessage: i == 0,
            displayAvatar: displayAvatar,
            displayName: displayName,
            addPaddingTop: displayPadding,
            edited: edited,
            onEventSelectedStream:
                onSelected?.where((eventId) => eventId == event.eventId),
            onReact: (e) => onReact(e, event),
            onReplyEventPressed: onReplyEventPressed,
            onReply: () => onReply(oldEvent)),
        if (event.receipts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2, right: 2),
            child: GestureDetector(
              onTap: () async {
                await AdaptativeDialogs.show(
                    context: context,
                    title: "Seen by",
                    builder: (context) => ReadReceiptsList(event: event));
              },
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                for (Receipt r in event.receipts
                    .where((r) => r.user.id != room.client.userID)
                    .take(12))
                  ReadReceiptsItem(r: r, room: room),
                if (event.receipts.length >= 12)
                  const CircleAvatar(
                      radius: 10, child: Icon(Icons.more_horiz, size: 14))
              ]),
            ),
          ),
        if (event.eventId == fullyReadEventId && nextEvent != null)
          const Row(
            children: [
              Expanded(
                  child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(),
              )),
              Text("Fully read"),
              Expanded(
                  child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(),
              ))
            ],
          ),
      ],
    );
  }
}
