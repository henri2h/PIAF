import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:minestrix/pages/feed/feed_page_view.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix/utils/minestrix/minestrix_notifications.dart';
import 'package:minestrix/chat/config/matrix_types.dart';
import 'package:minestrix/chat/partials/feed/posts/matrix_post_editor.dart';
import 'package:minestrix/chat/utils/matrix_widget.dart';

import '../../utils/settings.dart';

@RoutePage()
class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  FeedPageController createState() => FeedPageController();
}

class FeedPageController extends State<FeedPage> {
  ScrollController controller = ScrollController();
  Future<void> launchCreatePostModal(BuildContext context) async {
    final client = Matrix.of(context).client;
    await PostEditorPage.show(
        context: context, rooms: client.minestrixUserRoom);
  }

  List<Event>? events;
  CachedStreamController<int> syncIdStream = CachedStreamController();
  StreamSubscription? listener;
  String? clientUserId;

  void resetPage() {
    isGettingEvents = false;
    start = 0;
    _databaseTimelineEvents.clear();
    events = null;
    listener?.cancel();
    init();
  }

  Future<void> loadEvents() async {
    await Matrix.of(context).client.roomsLoading;
    await getEvents();
    syncIdStream.add(syncIdStream.value ?? 0 + 1);
  }

  void init() {
    Logs().w("Timeline hooking up");
    final client = Matrix.of(context).client;

    clientUserId = client.userID;

    listener = client.onNewPost.listen((event) async {
      Logs().w("Timeline refreshing page");
      await loadEvents();
    });

    loadEvents();
  }

  @override
  void initState() {
    super.initState();
    init();

    controller.addListener(onScroll);
  }

  @override
  void deactivate() {
    listener?.cancel();
    super.deactivate();
  }

  int start = 0;
  final List<Event> _databaseTimelineEvents = [];

  bool isGettingEvents = false;

  Future<List<Event>> getEvents() async {
    if (!Settings().optimizedFeed) {
      events = await Matrix.of(context).client.getMinestrixEvents();
    } else {
      if (isGettingEvents) return events ?? [];
      events = await requestEvents();
    }
    return events!;
  }

  Future<List<Event>> requestEvents() async {
    if (isGettingEvents) return [];
    isGettingEvents = true;

    final client = Matrix.of(context).client;
    try {
      Logs().w("Request history $start");
      /*
      In order to prevent the application to redraw the feed each time we recieve
      a new post, we make here a copy of the feed and refresh the feed only if the
      user press the reload button.
      TODO : Put this system in place again
      TODO : display a notification that a new post is available
    */

      await client.roomsLoading;
      final events = await client.database?.getEventListForType(
              MatrixTypes.post, client.rooms,
              start: start) ??
          [];

      start += events.length;

      final fevents = events
          .where((element) =>
              element.relationshipType == null && !element.redacted)
          .toList();

      // adding events
      _databaseTimelineEvents.addAll(fevents);

      isGettingEvents = false;
      return _databaseTimelineEvents;
    } catch (ex, stack) {
      Logs().e("Timeline fetching error", ex, stack);
      isGettingEvents = false;
      return [];
    }
  }

  Future<void> onScroll() async {
    if (controller.position.maxScrollExtent - controller.position.pixels <
        800) {
      if (!Settings().optimizedFeed) return;

      await requestEvents();
      if (mounted) setState(() {});
    }
  }

  Future<bool> roomsLoadingTest(BuildContext context) async {
    await Matrix.of(context).client.roomsLoading;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FeedPageView(this);
  }

  Future<void> onRefresh() async {
    resetPage();
    await loadEvents();
    if (mounted) {
      setState(() {});
    }
  }
}
