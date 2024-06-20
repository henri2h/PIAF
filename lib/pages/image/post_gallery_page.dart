import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/minestrix_chat.dart';
import 'package:piaf/partials/event/matrix_image.dart';
import 'package:piaf/partials/utils/extensions/minestrix/model/social_item.dart';

@RoutePage()
class PostGalleryPage extends StatefulWidget {
  final Event post;
  final Event? image;
  final String? selectedImageEventId;
  const PostGalleryPage(
      {super.key, required this.post, this.image, this.selectedImageEventId})
      : assert(image == null || selectedImageEventId == null);

  @override
  State<PostGalleryPage> createState() => _PostGalleryPageState();
}

class _PostGalleryPageState extends State<PostGalleryPage>
    with SingleTickerProviderStateMixin {
  Timeline? timeline;

  Set<Event>? reactions;
  Set<Event>? replies;
  Map<Event, dynamic>? nestedReplies;

  Future<Timeline> getTimeline(Event selectedEvent) async {
    if (timeline != null) return timeline!;
    timeline = await widget.post.room.getTimeline(onUpdate: () {
      if (timeline != null) {
        loadReactionForEvent(timeline!, selectedEvent);
        if (mounted) setState(() {});
      }
    });

    loadReactionForEvent(timeline!, selectedEvent);
    return timeline!;
  }

  void loadReactionForEvent(Timeline t, Event event) {
    reactions = event.getReactions(t);
    replies = event.getReplies(t);
    if (replies != null) nestedReplies = event.getNestedReplies(replies!);
  }

  final Map<String, Event?> _eventList = {};

  Future<Event?> getImage(String id) async {
    if (_eventList[id] != null) return _eventList[id];
    return _eventList[id] = await widget.post.room.getEventById(id);
  }

  @override
  void initState() {
    _controller = TabController(length: imgCount, vsync: this);
    _controller?.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  int get imgCount => widget.post.imagesRefEventId.length;
  TabController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Images"),
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          return Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    TabBarView(
                      controller: _controller,
                      children: [
                        for (final imgId in widget.post.imagesRefEventId)
                          FutureBuilder<Event?>(
                              future: getImage(imgId),
                              builder: (context, snap) {
                                return Builder(builder: (context) {
                                  if (!snap.hasData) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  final image = snap.data!;

                                  return InteractiveViewer(
                                    minScale: 0.01,
                                    maxScale: 4,
                                    child: MatrixEventImage(
                                      key: Key("img_event_${image.eventId}"),
                                      fit: BoxFit.contain,
                                      borderRadius: BorderRadius.zero,
                                      getThumbnail: false,
                                      event: image,
                                    ),
                                  );
                                });
                              }),
                      ],
                    ),
                    Positioned(
                        top: 12,
                        right: 12,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "${_controller!.index + 1}/$imgCount",
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ))
                  ],
                ),
              ),
              /*
          if (constraints.maxWidth > 1000)
            FutureBuilder<Timeline>(
                future: getTimeline(),
                builder: (context, snapshot) {
                  final t = snapshot.data;
                  return SizedBox(
                      width: 340,
                      child: ListView(
                        children: [
                          PostHeader(event: widget.post, allowContext: false),
                        ],
                      ));
                }),*/
              Center(
                child: TabPageSelector(controller: _controller),
              ),
            ],
          );
        }));
  }
}
