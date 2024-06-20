import 'dart:async';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/cached_stream_controller.dart'; // TODO: Find a solution
import 'package:piaf/config/matrix_types.dart';
import 'package:piaf/partials/minestrix_chat.dart';
import 'package:piaf/partials/chat/room/room_participants_indicator.dart';
import 'package:piaf/partials/chat/user/selector/user_selector_dialog.dart';
import 'package:piaf/partials/custom_list_view.dart';
import 'package:piaf/partials/stories/stories_list.dart';
import 'package:piaf/partials/utils/matrix_widget.dart';

import '../../partials/calendar_events/calendar_event_card.dart';
import '../../partials/feed/topic_list_tile.dart';
import '../../partials/post/post.dart';
import '../../partials/post/post_shimmer.dart';
import '../../partials/post/post_writer_modal.dart';

class FeedController {
  final stream = CachedStreamController<String>();
  bool enabled = false;
  void request() {
    if (enabled) {
      Logs().w("Requesting more posts");
      stream.add("request");
    }
  }
}

class CommunityFeed extends StatefulWidget {
  const CommunityFeed(
      {super.key,
      required this.space,
      required this.children,
      required this.controller,
      this.displayPostModal = true});

  final Room space;
  final List<Room> children;
  final FeedController controller;
  final bool displayPostModal;

  @override
  State<CommunityFeed> createState() => _CommunityFeedState();
}

class _CommunityFeedState extends State<CommunityFeed> {
  bool updating = false;

  late Room space;

  Future<List<Event>>? initLoading;

  @override
  void initState() {
    super.initState();
    space = widget.space;
    widget.controller.enabled = true;
  }

  Future<void> inviteUsers() async {
    List<String>? users = await MinesTrixUserSelection.show(context, space);

    users?.forEach((String userId) async {
      await widget.space.invite(userId);
    });

    setState(() {});
  }

  int start = 0;
  final List<Event> _databaseTimelineEvents = [];

  Future<List<Event>> requestEvents() async {
    if (updating) return [];
    updating = true;

    final client = Matrix.of(context).client;
    try {
      Logs().w("Request history $start");

      await client.roomsLoading;
      final events = <Event>[];

      // TODO: Reimplement post loading

      /*await client.database?.getEventListForType(MatrixTypes.post,
              widget.children.where((room) => room.isFeed).toList(),
              start: start) ??
          [];
*/
      start += events.length;

      final fevents = events
          .where((element) =>
              element.relationshipType == null && !element.redacted)
          .toList();

      // adding events
      _databaseTimelineEvents.addAll(fevents);

      // if we don't have any elements left. We shouldn't try to request more
      // elements. TODO: see if it's not just that all the elemntents returned
      // where irelevants. (relationshipType != null or redacted elements)
      if (fevents.isEmpty) {
        Logs().w("Reached bottom");
        widget.controller.enabled = false;
      }

      updating = false;
      return _databaseTimelineEvents;
    } catch (ex, stack) {
      Logs().e("Timeline fetching error", ex, stack);
      updating = false;
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final calendarRooms = widget.children
        .where((room) => room.type == MatrixTypes.calendarEvent)
        .toList();

    return StreamBuilder(
        stream: widget.controller.stream.stream,
        builder: (context, snapshot) {
          return FutureBuilder(
              future: requestEvents(),
              builder: (context, snapshot) {
                return CustomListViewWithEmoji(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _databaseTimelineEvents.length + 1,
                    itemBuilder: (BuildContext c, int i,
                        void Function(Offset, Event) onReact) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: RoomParticipantsIndicator(
                                            room: space),
                                      ),
                                      ElevatedButton(
                                          onPressed: inviteUsers,
                                          child: const Row(
                                            children: [
                                              Icon(Icons.person_add),
                                              SizedBox(width: 8),
                                              Text("Invite"),
                                            ],
                                          ))
                                    ],
                                  ),
                                ),
                                TopicListTile(room: space),
                                StoriesList(
                                  client: space.client,
                                  allowCreatingStory: false,
                                  restrictRoom: widget.children,
                                ),
                                if (calendarRooms.isNotEmpty)
                                  SizedBox(
                                    height: 290,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: calendarRooms.length,
                                      itemBuilder: ((context, index) => Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: SizedBox(
                                                width: 360,
                                                child: CalendarEventCard(
                                                    room:
                                                        calendarRooms[index])),
                                          )),
                                    ),
                                  ),
                                if (widget.displayPostModal)
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: PostWriterModal(room: space),
                                  ),
                              ]),
                        );
                      }
                      return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 2, horizontal: 12),
                          child: (i < _databaseTimelineEvents.length)
                              ? Post(
                                  event: _databaseTimelineEvents[i - 1],
                                  onReact: (e) => onReact(
                                      e, _databaseTimelineEvents[i - 1]))
                              : snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? const PostShimmer()
                                  : Container());
                    });
              });
        });
  }
}
