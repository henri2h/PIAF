import 'dart:async';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/custom_list_view.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import 'package:matrix/src/utils/cached_stream_controller.dart';

import '../../../partials/post/post.dart';
import '../../../partials/post/post_writer_modal.dart';

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

class LayoutMainFeed extends StatefulWidget {
  const LayoutMainFeed(
      {Key? key,
      required this.space,
      required this.children,
      required this.controller})
      : super(key: key);

  final Room space;
  final List<Room> children;
  final FeedController controller;

  @override
  State<LayoutMainFeed> createState() => _LayoutMainFeedState();
}

class _LayoutMainFeedState extends State<LayoutMainFeed> {
  bool updating = false;

  late Room space;

  Future<List<Event>>? initLoading;

  @override
  void initState() {
    super.initState();
    space = widget.space;
    widget.controller.enabled = true;
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
      final events = await client.database?.getEventListForType(
              MatrixTypes.post, widget.children,
              start: start) ??
          [];

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
                        return Column(children: [
                          if (space.avatar != null)
                            Center(
                                child: MatrixImageAvatar(
                                    client: space.client,
                                    url: space.avatar,
                                    unconstraigned: true,
                                    shape: MatrixImageAvatarShape.none,
                                    maxHeight: 500)),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: PostWriterModal(room: space),
                          ),
                        ]);
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
