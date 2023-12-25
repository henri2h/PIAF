import 'dart:async';

import 'package:flutter/material.dart';
import 'package:infinite_list/infinite_list.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/chat/message_composer/matrix_advanced_message_composer.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import '../../infinite_custom_list_view.dart';
import '../typing_indicator.dart';
import 'item_builder.dart';

class RoomTimeline extends StatefulWidget {
  final Room? room;
  final Client client;
  final String? userId;
  final Timeline? timeline;
  final Function(bool) setUpdating;
  final bool disableTimelinePadding;
  final bool isMobile;

  final void Function(Room)? onRoomCreate;

  final bool updating;
  const RoomTimeline(
      {super.key,
      required this.room,
      required this.client,
      required this.isMobile,
      this.userId,
      this.disableTimelinePadding = false,
      this.onRoomCreate,
      required this.timeline,
      required this.updating,
      required this.setUpdating});

  @override
  RoomTimelineState createState() => RoomTimelineState();
}

class RoomTimelineState extends State<RoomTimeline> {
  static const double bottomPadding = 60;

  late String? initialFullyReadEventId;
  String? fullyReadEventId;
  StreamController<String> onRelpySelected = StreamController.broadcast();
  Event? composerReplyToEvent;
  Room? room;
  List<Event> filteredEvents = [];

  Future<void>? request;

  // scrolling logic
  final _scrollController = AutoScrollController(
    initialScrollOffset: -bottomPadding,
  ); // initial scroll offset due to list padding
  InfiniteListController? controller;

  @override
  void initState() {
    super.initState();
    room = widget.room ?? widget.timeline?.room;

    initialFullyReadEventId = room?.fullyRead;
    fullyReadEventId = initialFullyReadEventId;

    _scrollController.addListener(scrollListener);
    controller = InfiniteListController(
        items: filteredEvents, scrollController: _scrollController);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (room != null) {
        markLastRead(room: room!);
      }
    });
  }

  @override
  void deactivate() {
    super.deactivate();
    _scrollController.removeListener(scrollListener);
  }

  bool get hasScrollReachedBottom =>
      _scrollController.position.pixels -
          _scrollController.position.minScrollExtent <
      10;

  void scrollListener() async {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 600) {
      if (widget.updating == false &&
          (widget.timeline?.canRequestHistory ?? false)) {
        widget.setUpdating(true);
        await widget.timeline?.requestHistory();
        widget.setUpdating(false);
      }
    }
    if (_scrollController.hasClients) {
      controller?.useFirstItemAsCenter = hasScrollReachedBottom;
    }
  }

  Future<void> requestHistoryIfNeeded() async {
    while ((widget.timeline?.canRequestHistory ?? false) &&
        _scrollController.hasClients &&
        _scrollController.position.hasContentDimensions &&
        _scrollController.position.maxScrollExtent == 0) {
      if (widget.timeline?.isRequestingHistory ?? false) {
        Future.delayed(const Duration(milliseconds: 200));
      } else {
        await widget.timeline?.requestHistory();
      }
    }
  }

  bool init = false;

  @override
  Widget build(BuildContext context) {
    if (!init) {
      if (widget.timeline?.events.isNotEmpty == true && room != null) {
        init = true;
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (room != null) markLastRead(room: room!);
        });
      }
    }

    if (request == null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (_scrollController.hasClients &&
            _scrollController.position.hasContentDimensions &&
            widget.timeline != null) {
          request ??= requestHistoryIfNeeded();
        }
      });
    }

    filteredEvents.clear();
    filteredEvents.addAll(filter(widget.timeline?.events) ?? []);

    return Stack(children: [
      room != null
          ? Padding(
              padding:
                  EdgeInsets.only(bottom: widget.isMobile ? 0 : bottomPadding),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: InfiniteCustomListViewWithEmoji(
                    controller: controller!,
                    reverse: true,
                    itemCount: filteredEvents.length,
                    padding: EdgeInsets.only(
                        top: widget.disableTimelinePadding ? 0 : 52,
                        bottom: !widget.isMobile ? 0 : bottomPadding),
                    itemBuilder: (BuildContext context, int index,
                            ItemPositions position, onReact) =>
                        ItemBuilder(
                          key: index < filteredEvents.length
                              ? Key("item_${filteredEvents[index].eventId}")
                              : null,
                          room: room!,
                          filteredEvents: filteredEvents,
                          t: widget.timeline,
                          i: index,
                          onReact: onReact,
                          position: position,
                          onReplyEventPressed: (event) async {
                            final index = widget.timeline!.events.indexOf(
                                event.getDisplayEvent(widget.timeline!));
                            if (index != -1) {
                              await controller?.scrollController
                                  .scrollToIndex(index);
                              onRelpySelected.add(event.eventId);
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "Could not scroll to index, item not found")));
                              }
                            }
                          },
                          onSelected: onRelpySelected.stream,
                          onReply: (Event oldEvent) => setState(() {
                            composerReplyToEvent = oldEvent;
                          }),
                          fullyReadEventId: initialFullyReadEventId,
                        )),
              ),
            )
          : widget.userId?.startsWith("@") == true // Is a user
              ? FutureBuilder<Profile>(
                  future: widget.client.getProfileFromUserId(widget.userId!),
                  builder: (context, snap) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MatrixImageAvatar(
                            url: snap.data?.avatarUrl,
                            client: widget.client,
                            height: MinestrixAvatarSizeConstants.big,
                            width: MinestrixAvatarSizeConstants.big,
                            shape: MatrixImageAvatarShape.rounded,
                            defaultText: snap.data?.displayName,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                              child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 34),
                            child: ListTile(
                              title: Text(
                                  snap.data?.displayName ?? widget.userId!,
                                  style: const TextStyle(fontSize: 24)),
                              subtitle: Text(widget.userId!,
                                  style: const TextStyle(fontSize: 18)),
                            ),
                          )),
                        ],
                      ),
                    );
                  })
              : const Center(child: Text("An error happened")),
      Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (User user in room?.typingUsers ?? [])
            TypingIndicator(room: room!, user: user),
          MatrixAdvancedMessageComposer(
              room: room,
              isMobile: widget.isMobile,
              userId: widget.userId,
              client: widget.client,
              onRoomCreate: widget.onRoomCreate,
              reply: composerReplyToEvent,
              removeReply: () {
                setState(() {
                  composerReplyToEvent = null;
                });
              }),
        ],
      )
    ]);
  }

  List<Event>? filter(List<Event>? events) => events
      ?.where((e) =>
          !{RelationshipTypes.edit, RelationshipTypes.reaction}
              .contains(e.relationshipType) &&
          !{
            EventTypes.Reaction,
            EventTypes.Redaction,
            EventTypes.CallCandidates,
            EventTypes.CallHangup,
            EventTypes.CallReject,
            EventTypes.CallNegotiate,
            EventTypes.CallAnswer,
            "m.call.select_answer",
            "org.matrix.call.sdp_stream_metadata_changed"
          }.contains(e.type))
      .toList();

  /// send a read event if we have read the last event
  Future<bool> markLastRead({required Room room}) async {
    // Only update the read marker if the user is in the room.
    // Room marker can't be updated if we are peeking the room
    if (room.membership != Membership.invite) return false;

    if (widget.timeline?.events.isNotEmpty != true) return false;

    Event? lastEvent;

    // get last read item
    if (hasScrollReachedBottom) {
      lastEvent = widget.timeline?.events.first;
    } else {
      lastEvent = controller?.getClosestElementToAlignment();
    }

    if (lastEvent != null &&
        fullyReadEventId != lastEvent.eventId &&
        lastEvent.status.isSent) {
      final lastReadPos = widget.timeline!.events
          .indexWhere((element) => element.eventId == fullyReadEventId);
      final pos = widget.timeline!.events.indexOf(lastEvent);

      if (lastReadPos != -1 && pos >= lastReadPos) return false;

      final evId = lastEvent.eventId;
      fullyReadEventId = evId;

      await room.setReadMarker(evId, mRead: evId);
      return true;
    }
    return false;
  }
}
