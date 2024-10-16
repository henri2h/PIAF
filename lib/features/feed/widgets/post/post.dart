import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/features/feed/widgets/post/post_item.dart';

import '../../../../../router.gr.dart';

class Post extends StatefulWidget {
  final Event event;
  final void Function(Offset) onReact;
  final Timeline? timeline;
  const Post(
      {super.key, required this.event, required this.onReact, this.timeline});

  @override
  State<Post> createState() => _PostState();
}

class _PostState extends State<Post> {
  Timeline? timeline;

  late Future<Timeline> futureTimeline;

  @override
  void initState() {
    futureTimeline = getTimeline();
    super.initState();
  }

  Future<Timeline> getTimeline() async {
    timeline = widget.timeline ??
        await widget.event.room.getTimeline(onUpdate: () {
          if (timeline != null) {
            if (mounted) setState(() {});
          }
        });

    return timeline!;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 500;

      final post = InkWell(
        onTap: () {
          if (timeline != null) {
            context
                .pushRoute(PostRoute(timeline: timeline!, event: widget.event));
          }
        },
        child: FutureBuilder<Timeline?>(
            future: futureTimeline,
            builder: (context, snap) {
              return PostItem(
                  event: widget.event,
                  onReact: widget.onReact,
                  timeline: snap.data,
                  isMobile: isMobile);
            }),
      );

      if (isMobile) {
        return post;
      }

      return Card(child: post);
    });
  }
}
