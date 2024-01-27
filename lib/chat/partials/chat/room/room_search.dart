import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matrix/matrix.dart';

import '../../../style/constants.dart';
import '../event/event_widget.dart';

enum Selection { room, all }

class RoomSearch extends StatefulWidget {
  const RoomSearch({super.key, required this.room, this.onClosePressed});
  final Room room;
  final VoidCallback? onClosePressed;

  @override
  State<RoomSearch> createState() => _RoomSearchState();
}

class _RoomSearchState extends State<RoomSearch> {
  Set<Selection> _selected = {Selection.room};
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  var focusNode = FocusNode();

  bool _searching = false;

  String? _searchText;
  SearchResults? _lastResult;

  final StreamController<SearchResults> _results = StreamController.broadcast();

  Future<void>? scrollSearch;
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() async {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 600) {
        if (scrollSearch == null) {
          scrollSearch = launchSearch(scroll: true);
          await scrollSearch;
          scrollSearch = null;
        }
      }
    });
  }

  Future<void> search(String text, {bool scroll = false}) async {
    if (!scroll) {
      _lastResult = null;
    } else {
      // if we already got all the results, there is no need to try requesting the server for new responses
      if (_lastResult!.searchCategories.roomEvents!.results!.length ==
          _lastResult!.searchCategories.roomEvents!.count) return;
    }

    setState(() {
      _searching = true;
    });
    final searchFilter = SearchFilter(
        rooms: _selected.contains(Selection.all) ? null : [widget.room.id],
        limit: 10);
    final result = await widget.room.client.search(
        Categories(
          roomEvents: RoomEventsCriteria(
              searchTerm: text,
              orderBy: SearchOrder.recent,
              eventContext: IncludeEventContext(afterLimit: 1, beforeLimit: 1),
              filter: searchFilter),
        ),
        nextBatch: _lastResult?.searchCategories.roomEvents?.nextBatch);

    if (scroll && _lastResult != null) {
      _lastResult!.searchCategories.roomEvents!.results!
          .addAll(result.searchCategories.roomEvents!.results!);

      result.searchCategories.roomEvents!.results =
          _lastResult!.searchCategories.roomEvents!.results;
    }
    _lastResult = result;
    _results.add(result);

    setState(() {
      _searching = false;
    });
  }

  Future<void> launchSearch({bool scroll = false}) async {
    if (!scroll) {
      _results.add(SearchResults(searchCategories: ResultCategories()));
    }
    if (_searchText != null) {
      await search(_searchText!, scroll: scroll);
    }
  }

  void onEdit(String? text) {
    _searchText = text;
    if (text == null) return;
    /*
    searchTimer?.cancel();
    searchTimer = Timer(const Duration(milliseconds: 500), () async {
      await search(text);
    });*/
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.room.client;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: KeyboardListener(
                  focusNode: focusNode,
                  onKeyEvent: (KeyEvent key) {
                    if (key.logicalKey == LogicalKeyboardKey.enter) {
                      launchSearch();
                    }
                  },
                  child: TextField(
                      controller: _controller,
                      onChanged: onEdit,
                      autofocus: true,
                      decoration: Constants.kBasicSearch.copyWith(
                          hintText: "Search",
                          suffixIcon: IconButton(
                              onPressed: launchSearch,
                              icon: const Icon(Icons.search)))),
                ),
              ),
              if (widget.onClosePressed != null)
                IconButton(
                    onPressed: widget.onClosePressed,
                    icon: const Icon(Icons.close))
            ],
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SegmentedButton<Selection>(
                onSelectionChanged: (value) {
                  setState(() {
                    _selected = value;
                  });
                  launchSearch();
                },
                segments: const [
                  ButtonSegment(
                      value: Selection.room,
                      icon: Icon(Icons.chat),
                      label: Text("In the room")),
                  ButtonSegment(
                      value: Selection.all,
                      icon: Icon(Icons.home),
                      label: Text("Everywhere"))
                ],
                selected: _selected),
          ),
        ),
        Expanded(
          child: ListView(
            controller: _scrollController,
            reverse: true,
            children: [
              StreamBuilder<SearchResults>(
                  stream: _results.stream,
                  builder: (context, snapshot) {
                    final data = snapshot.data?.searchCategories.roomEvents;
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data?.results == null) const Text("Enter text"),
                          if (data?.count != null)
                            Text(" ${data?.count} results"),
                          Text(" ${data?.nextBatch} batch"),
                          if (data?.results != null)
                            for (int i = data!.results!.length - 1; i >= 0; i--)
                              Builder(builder: (context) {
                                final item = data.results![i];
                                if (item.result?.roomId == null) {
                                  return const Text("no event");
                                }
                                final room =
                                    client.getRoomById(item.result!.roomId!);
                                if (room == null) const Text("No room found");
                                bool sameRoomAsPrev = false;
                                if (i + 1 < data.results!.length) {
                                  sameRoomAsPrev = item.result?.roomId ==
                                      data.results![i + 1].result?.roomId;
                                }

                                final event =
                                    Event.fromMatrixEvent(item.result!, room!);
                                return Column(
                                  children: [
                                    if (!sameRoomAsPrev)
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          children: [
                                            const Expanded(
                                                child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 20),
                                              child: Divider(),
                                            )),
                                            Text(room.getLocalizedDisplayname(
                                                const MatrixDefaultLocalizations())),
                                            const Expanded(
                                                child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 20),
                                              child: Divider(),
                                            ))
                                          ],
                                        ),
                                      ),
                                    if (item.context?.eventsBefore != null)
                                      for (final event
                                          in item.context!.eventsBefore!)
                                        Opacity(
                                          opacity: 0.6,
                                          child: EventWidget(
                                              client: client,
                                              event: Event.fromMatrixEvent(
                                                  event, room),
                                              addPaddingTop: true,
                                              displayAvatar: true,
                                              displayName: true),
                                        ),
                                    EventWidget(
                                        client: client,
                                        event: event,
                                        addPaddingTop: true,
                                        displayAvatar: true,
                                        displayName: true),
                                    if (item.context?.eventsAfter != null)
                                      for (final event
                                          in item.context!.eventsAfter!)
                                        Opacity(
                                          opacity: 0.6,
                                          child: EventWidget(
                                              client: client,
                                              event: Event.fromMatrixEvent(
                                                  event, room),
                                              addPaddingTop: true,
                                              displayAvatar: true,
                                              displayName: true),
                                        ),
                                  ],
                                );
                              }),
                          if (_searching)
                            const ListTile(
                              title: Text("Searching..."),
                              leading: CircularProgressIndicator(),
                            ),
                        ],
                      ),
                    );
                  }),
            ],
          ),
        ),
      ],
    );
  }
}
