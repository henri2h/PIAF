import 'dart:async';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../../event/matrix_image.dart';

class ConvSettingsRoomMedia extends StatefulWidget {
  const ConvSettingsRoomMedia({super.key, required this.room});

  final Room room;

  @override
  State<ConvSettingsRoomMedia> createState() => _ConvSettingsRoomMediaState();
}

class _ConvSettingsRoomMediaState extends State<ConvSettingsRoomMedia> {
  Future<List<Event>>? futureEvents;
  final controller = ScrollController();

  final streamController = StreamController<List<Event>>();
  int eventLen = 0;

  bool requesting = false;

  Future<Timeline>? _futureTimeline;
  Future<InMemoryMediaTimeline>? _futureInMemoryMediaTimeline;
  int start = 0;
  bool isGettingEvents = false;

  Future<void> loadTimeline(int more) async {
    if (requesting) return;

    requesting = true;
    if (mounted) {
      setState(() {
        requesting = true;
      });
    }
    try {
      if (widget.room.encrypted) {
        await requestEncryptedTimeline(more);
      } else {
        await requestInMemoryMediaTimeline(more);
      }
    } finally {
      requesting = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> requestEncryptedTimeline(int more) async {
    _futureTimeline ??= widget.room.getTimeline();
    final timeline = await _futureTimeline!;

    int requestCount = 0;
    final prevCount = eventLen;

    while ((await getEvents(timeline.events)).length - prevCount < more &&
        requestCount < more &&
        timeline.canRequestHistory &&
        mounted) {
      await Future.delayed(
          const Duration(milliseconds: 400)); // do not surcharche the client
      await timeline.requestHistory();
      requestCount++;
    }
  }

  Future<void> requestInMemoryMediaTimeline(int more) async {
    _futureInMemoryMediaTimeline ??=
        InMemoryMediaTimeline.getTimeline(widget.room);
    final timeline = await _futureInMemoryMediaTimeline!;

    int requestCount = 0;
    final prevCount = eventLen;

    while ((await getEvents(timeline.events)).length - prevCount < more &&
        requestCount < more &&
        timeline.canRequestHistory &&
        mounted) {
      await Future.delayed(
          const Duration(milliseconds: 400)); // do not surcharche the client
      await timeline.requestHistory();
      requestCount++;
    }
  }

  @override
  void initState() {
    super.initState();
    loadTimeline(20);
    controller.addListener(onScroll);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<List<Event>> getEvents(List<Event> eventsIn) async {
    final events = eventsIn
        .where((event) =>
            !event.redacted && event.messageType == MessageTypes.Image)
        .toList();

    if (mounted && events.isNotEmpty) streamController.add(events);
    eventLen = events.length;
    return events;
  }

  Future<void> onScroll() async {
    if (mounted &&
        controller.hasClients &&
        controller.position.maxScrollExtent - controller.position.pixels <
            2000) {
      await loadTimeline(4); // load 4 more events or do 4 history request
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Event>>(
        stream: streamController.stream,
        builder: (context, snap) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
                title: const Text("Room media"),
                forceMaterialTransparency: true),
            body: Builder(builder: (context) {
              if (!snap.hasData) return const CircularProgressIndicator();
              if (snap.hasError) return Text(snap.error.toString());

              final events = snap.data!;
              if (events.isEmpty && !requesting) {
                return const ListTile(
                    leading: Icon(Icons.hourglass_empty), title: Text("Empty"));
              }
              return GridView.builder(
                controller: controller,
                itemCount: events.length + (requesting ? 1 : 0),
                cacheExtent: 800,
                itemBuilder: (BuildContext context, int index) =>
                    index >= events.length
                        ? const Center(child: CircularProgressIndicator())
                        : Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: SizedBox(
                              height: 100,
                              child: MImageViewer(
                                  event: events[index], fit: BoxFit.cover),
                            ),
                          ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 100),
              );
            }),
          );
        });
  }
}

extension Size on Event {
  String getSize() {
    if (infoMap["size"] is int) {
      int size = infoMap["size"] ~/ 1024;
      if (size < 1024) {
        return "$size Kb";
      }

      size = size ~/ 1024;

      if (size < 1024) {
        return "$size Mb";
      }

      size = size ~/ 1024;

      return "$size Gb";
    }
    return "";
  }
}

class InMemoryMediaTimeline {
  static const String filter =
      '{"lazy_load_members":true,"types":["m.room.message"],"not_types":[],"rooms":null,"not_rooms":[],"senders":null,"not_senders":[],"contains_url":true,"related_by_senders":[],"related_by_rel_types":[]}';

  List<Event> events = [];
  final Room room;
  String start = "";
  String? end;

  InMemoryMediaTimeline(this.room);

  bool get canRequestHistory => end != null;

  static Future<InMemoryMediaTimeline> getTimeline(Room room) async {
    final eventsResponse = await room.client
        .getRoomEvents(room.id, Direction.b, filter: filter, limit: 4);

    final timeline = InMemoryMediaTimeline(room);
    timeline.events = timeline.getEvents(eventsResponse);
    timeline.start = eventsResponse.start;
    timeline.end = eventsResponse.end;

    return timeline;
  }

  Future<void> requestHistory() async {
    final eventsResponse = await room.client
        .getRoomEvents(room.id, Direction.b, filter: filter, from: end);

    final newEvents = getEvents(eventsResponse);
    end = eventsResponse.end;

    events.addAll(newEvents);
  }

  List<Event> getEvents(GetRoomEventsResponse response) {
    return response.chunk
        .map((matrixEvent) => Event.fromMatrixEvent(matrixEvent, room))
        .toList();
  }
}
