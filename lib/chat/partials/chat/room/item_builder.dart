import 'package:flutter/material.dart';
import 'package:infinite_list/infinite_list.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/date_time_extension.dart';

import '../../dialogs/adaptative_dialogs.dart';
import '../event/event_widget.dart';
import '../event/read_receipts/read_receipt_item.dart';
import '../event/read_receipts/read_receipts_list.dart';
import 'fully_read_indicator.dart';

class ItemBuilder extends StatelessWidget {
  const ItemBuilder(
      {super.key,
      this.displayAvatar = false,
      this.displayRoomName = false,
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
      this.fullyReadEventId,
      required this.isDirectChat});

  final Room room;
  final Timeline? t;
  final List<Event> filteredEvents;
  final bool displayAvatar;
  final bool displayRoomName;
  final bool displayTime;
  final bool displayPadding;
  final void Function(Offset, Event) onReact;
  final ItemPositions position;
  final int i;
  final void Function(Event) onReplyEventPressed;
  final void Function(Event) onReply;
  final Stream<String>? onSelected;
  final String? fullyReadEventId;
  final bool isDirectChat;

  @override
  Widget build(BuildContext context) {
    // local overrides
    bool displayRoomName = this.displayRoomName;
    bool displayTime = this.displayTime;
    bool displayPadding = this.displayPadding;
    bool displayAvatar = this.displayAvatar;

    if (position != ItemPositions.item) return Container();
    Event event = filteredEvents[i];

    Set<Event> reactions =
        t == null ? {} : event.aggregatedEvents(t!, RelationshipTypes.reaction);

    final prevEvent =
        i < filteredEvents.length - 1 ? filteredEvents[i + 1] : null;
    final nextEvent = i > 0 ? filteredEvents[i - 1] : null;

    if (prevEvent != null) {
      // check if the preceding message was sent by the same user
      // TODO : check dates
      if (event.type == EventTypes.Message) {
        if (event.senderId != prevEvent.senderId) {
          displayRoomName = !isDirectChat;
          displayPadding = true;
        }

        displayTime = displayTime || shouldDisplayTime(event, prevEvent);
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
    if (t != null) {
      event = event.getDisplayEvent(t!);
    }
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
            child: Text(event.originServerTs.timeSinceInDays,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ),
        EventWidget(
            key: Key("ed_${event.eventId}"),
            event: event,
            timeline: t,
            reactions: reactions,
            client: room.client,
            isLastMessage: i == 0,
            displayAvatar: displayAvatar,
            displayName: displayRoomName,
            addPaddingTop: displayPadding,
            edited: edited,
            onEventSelectedStream:
                onSelected?.where((eventId) => eventId == event.eventId),
            onReact: (e) => onReact(e, event),
            onReplyEventPressed: onReplyEventPressed,
            onReply: (_) => onReply(oldEvent)),

        // Disable read receipts in large group as it's quit costly
        // in terms of performance.
        if ((room.summary.mJoinedMemberCount ?? 0) < 60 &&
            event.receipts.isNotEmpty)
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
          const FullyReadIndicator(),
      ],
    );
  }

  bool shouldDisplayTime(Event event, Event prevEvent) {
    if (event.originServerTs
            .difference(prevEvent.originServerTs)
            .inHours
            .abs() >=
        12) {
      return true;
    }
    return false;
  }
}
