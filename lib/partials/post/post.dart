import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'post_view.dart';

class Post extends StatefulWidget {
  final Event event;
  final void Function(Offset) onReact;
  final Timeline? timeline;
  Post({Key? key, required this.event, required this.onReact, this.timeline})
      : super(key: key);

  @override
  PostState createState() => PostState();
}

enum PostTypeUpdate { ProfilePicture, DisplayName, Membership, None }

class PostState extends State<Post> with SingleTickerProviderStateMixin {
  final key = GlobalKey();
  bool showReplyBox = true;
  bool showReplies = true;

  late Future<Timeline> futureTimeline;

  Event get event => widget.event;

  void setReplyVisibility(bool value) => setState(() {
        showReplyBox = value;
      });

  @override
  void initState() {
    if (widget.timeline == null) {
      futureTimeline = widget.event.room.getTimeline();
    } else {
      futureTimeline = () async {
        return widget.timeline!;
      }();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PostView(controller: this);
  }

  void replyButtonClick() {
    setState(() {
      showReplyBox = !showReplyBox;
    });
  }

  void toggleReplyView() {
    setState(() {
      showReplies = !showReplies;
    });
  }

  void onReact(Offset globalPosition) {
    widget.onReact(globalPosition);
  }
}
