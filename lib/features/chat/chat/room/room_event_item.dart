import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/utils/date_time_extension.dart';

import '../../../../partials/dialogs/adaptative_dialogs.dart';
import '../../../../partials/emoji/custom_emoji_picker.dart';
import '../../../../partials/emoji/emoji_picker.dart';
import '../../../../partials/popup_route_wrapper.dart';
import '../../../../utils/platforms_info.dart';
import '../../widgets/event/event_widget.dart';
import '../../widgets/event/read_receipts/read_receipts_list.dart';
import '../../widgets/room/fully_read_indicator.dart';
import '../event/read_receipts/read_receipt_item.dart';

class RoomEventDisplaySetting {
  final bool displayAvatar;

  final bool displayRoomName;
  final bool displayTime;
  final bool displayPadding;

  RoomEventDisplaySetting(
      {required this.displayRoomName,
      required this.displayTime,
      required this.displayPadding,
      required this.displayAvatar});
}

class RoomEventItem extends StatelessWidget {
  const RoomEventItem(
      {super.key,
      this.displayAvatar = false,
      this.displayRoomName = false,
      this.displayTime = false,
      this.displayPadding = false,
      required this.room,
      required this.t,
      required this.filteredEvents,
      required this.i,
      required this.onReplyEventPressed,
      required this.onReply,
      this.eventsToAnimateStream,
      this.fullyReadEventId,
      required this.isDirectChat});

  final Room room;
  final Timeline? t;
  final List<Event> filteredEvents;
  final bool displayAvatar;
  final bool displayRoomName;
  final bool displayTime;
  final bool displayPadding;
  final int i;
  final void Function(Event) onReplyEventPressed;
  final void Function(Event) onReply;
  // To display an annimation when this event is selected
  final Stream<String>? eventsToAnimateStream;
  final String? fullyReadEventId;
  final bool isDirectChat;

  @override
  Widget build(BuildContext context) {
    // local overrides
    bool displayRoomName = this.displayRoomName;
    bool displayTime = this.displayTime;
    bool displayPadding = this.displayPadding;
    bool displayAvatar = this.displayAvatar;

    if (i >= filteredEvents.length) {
      return Text("Invalid item $i");
    }

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

    if (!isDirectChat &&
        (nextEvent?.senderId != event.senderId ||
            nextEvent?.type != EventTypes.Message)) {
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

    final eventContext = RoomEventContext(
        prevEvent: displayTime ? null : prevEvent,
        nextEvent: nextEvent,
        event: event,
        oldEvent: oldEvent,
        timeline: t,
        reactions: reactions,
        isDirectChat: isDirectChat,
        edited: edited,
        isLastMessage: i == 0);

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
            ctx: eventContext,
            displayAvatar: displayAvatar,
            displayName: displayRoomName,
            addPaddingTop: displayPadding,
            onEventSelectedStream: eventsToAnimateStream
                ?.where((eventId) => eventId == event.eventId),
            onReact: (offset) async {
              HapticFeedback.heavyImpact();

              await Navigator.of(context).push(PopupRouteWrapper(
                  anchorKeyContext: context,
                  useAnimation: false,
                  offset: offset,
                  maxHeight: 150,
                  builder: (rect) {
                    return ReactionBox(rect, event: event);
                  }));
            },
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

class ReactionBox extends StatefulWidget {
  const ReactionBox(this.rect, {super.key, required this.event});
  final Rect rect;
  final Event event;

  @override
  State<ReactionBox> createState() => _ReactionBoxState();
}

class _ReactionBoxState extends State<ReactionBox> {
  @override
  Widget build(BuildContext context) {
    return Listener(
        key: key,
        onPointerDown: (e) {
          _detectTapedItem(e, isEventPointerDown: true);
        },
        onPointerUp: _selectTapedItem,
        onPointerMove: _detectTapedItem,
        onPointerHover: _detectTapedItem,
        //onPointerUp: _clearSelection,
        behavior: HitTestBehavior.translucent,
        child: Align(
            alignment: Alignment.topLeft,
            child: Transform.translate(
                offset: widget.rect.topLeft,
                child: SizedBox(
                    width: widget.rect.width,
                    height: widget.rect.height,
                    child: MinestrixEmojiPicker(
                      width: 100,
                      height: 100,
                      selectedEmoji: _selectedEmoji,
                      selectedEdge: _emojiPickerEdge,
                      enableDelete:
                          widget.event.canRedact && !widget.event.redacted,
                      //enableEdit: _selectedEvent?.canRedact ?? false,
                      //enableReply: true,
                    )))));
  }

  String? _selectedEmoji;

  EdgeInsets? _emojiPickerEdge;

  /// in order to detect when the distance between the cursor and the widget
  double _emojiItemHeight = 0;

  final GlobalKey key = GlobalKey();
  Future<void>? res;

  void _detectTapedItem(PointerEvent event, {bool isEventPointerDown = false}) {
    final RenderBox? box = key.currentContext!.findRenderObject() as RenderBox?;

    if (box != null) {
      final result = BoxHitTestResult();
      Offset offset = box.globalToLocal(event.position);

      if (box.hitTest(result, position: offset)) {
        for (final hit in result.path) {
          /// temporary variable so that the [is] allows access of [index]
          final target = hit.target;
          if (target is EmojiPickerRenderProxy) {
            EmojiPickerRenderProxy t = target;
            // did previously update?
            if (t.index != _selectedEmoji) {
              setState(() {
                _selectedEmoji = t.index;
              });

              res = HapticFeedback.heavyImpact();
              _emojiItemHeight = event.position.dy;
            }
            return;
          }
        }

        // hide emoji picker when the cursor leave the emoji picker and a emoji has been selected
        if (_selectedEmoji != null) {
          double verticalDistance = _emojiItemHeight - event.position.dy;
          if (verticalDistance < 0) verticalDistance = -verticalDistance;

          if (verticalDistance > 40) _clearSelection(null);
        }

        // for desktop, hide emoji picker when clicked on an other part of the screen
        if (isEventPointerDown) {
          _clearSelection(null);
        }
      } else {
        if (_selectedEmoji != null) {
          _clearSelection(null);
        }
      }
    } else {
      _clearSelection(null);
    }
  }

  void _selectTapedItem(_) async {
    if (_selectedEmoji != null) {
      Navigator.of(context).pop();
      if (_selectedEmoji == "+") {
        Emoji? emoji;
        if (PlatformInfos.isAndroid) {
          emoji = await Navigator.of(context).push(EmojiPopupRoute());
        } else {
          emoji = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return const Dialog(child: CustomEmojiPickerGrid());
              });
        }
        _selectedEmoji = emoji?.emoji;
      }

      if (_selectedEmoji != null) {
        switch (_selectedEmoji) {
          case "reply":
          case "edit":
            break;
          case "delete":
            if (mounted) {
              final result = await showTextInputDialog(
                useRootNavigator: false,
                context: context,
                title: "Confirm removal",
                message:
                    "Are you sure you wish to remove this event? This cannot be undone.",
                okLabel: "Remove",
                textFields: [
                  const DialogTextField(
                      hintText: "Reason (optional)", initialText: "")
                ],
              );
              if (result?.isNotEmpty ?? false) {
                await widget.event.redactEvent(reason: result?.first);
              }
            }

            break;
          default:
            await widget.event.room
                .sendReaction(widget.event.eventId, _selectedEmoji!);
        }
      }
    }
  }

  void _clearSelection(PointerUpEvent? event) {
    setState(() {
      _selectedEmoji = null;
    });
  }
}
