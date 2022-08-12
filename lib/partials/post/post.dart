import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/partials/feed/posts/matrix_post_editor.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/utils/social/posts/model/social_item.dart';
import 'package:minestrix_chat/utils/matrix/client_extension.dart';
import 'package:minestrix_chat/utils/social/posts/posts_event_extension.dart';
import '../../utils/settings.dart';
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
  String? replyToMessageId = null;
  bool showReplies = false;

  Set<Event>? reactions;
  Set<Event>? replies;
  Map<Event, dynamic>? nestedReplies;

  late Future<Timeline> futureTimeline;

  Future<Event?>? shareEvent;

  bool get canShare =>
      Settings().shareEnabled &&
      widget.event.room.historyVisibility == HistoryVisibility.worldReadable &&
      widget.event.room.client.minestrixUserRoom.isNotEmpty;

  void setRepliedMessage(String? value) => setState(() {
        replyToMessageId = value;
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

    if (post.shareEventId != null && post.shareEventRoomId != null) {
      shareEvent = widget.event.room.client.getEventFromArbitraryRoomById(
          post.shareEventId!, post.shareEventRoomId!);
    }

    futureTimeline = getTimeline();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PostView(controller: this);
  }

  void loadPost(Timeline t) {
    reactions = post.event!.getReactions(t);
    replies = post.event!.getReplies(t);
    if (replies != null) nestedReplies = post.event!.getNestedReplies(replies!);
  }

  void replyButtonClick() {
    setState(() {
      if (replyToMessageId != widget.event.eventId) {
        replyToMessageId = widget.event.eventId;
      } else {
        replyToMessageId = null;
      }
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

  Future<void> share() async {
    await PostEditorPage.show(
        context: context,
        shareEvent: widget.event,
        rooms: Matrix.of(context).client.minestrixUserRoom);
  }
}
