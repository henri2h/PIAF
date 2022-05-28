import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/utils/social/posts/model/social_item.dart';

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

  Set<Event>? reactions;
  Set<Event>? replies;
  Map<Event, dynamic>? nestedReplies;

  late Future<Timeline> futureTimeline;

  void setEditBoxVisibility(bool value) => setState(() {
        showReplyBox = value;
      });

  late SocialItem post;

  Timeline? timeline;

  Future<Timeline> getTimeline() async {
    timeline = widget.timeline ??
        await widget.event.room.getTimeline(onUpdate: () {
          if (timeline != null) {
            loadPost(timeline!);
            if (mounted) setState(() {});
          }
        });

    loadPost(timeline!); // TODO: hook load post to refresh
    return timeline!;
  }

  @override
  void initState() {
    post = SocialItem.fromEvent(e: widget.event);

    futureTimeline = getTimeline();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PostView(controller: this);
  }

  void loadPost(Timeline t) {
    reactions = post.getReactions(t);
    replies = post.getReplies(t);
    if (replies != null) nestedReplies = post.getNestedReplies(replies!);
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
