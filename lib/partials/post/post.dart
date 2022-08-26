import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/partials/components/shimmer_widget.dart';
import 'package:minestrix_chat/partials/feed/posts/matrix_post_editor.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
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
  const Post(
      {Key? key, required this.event, required this.onReact, this.timeline})
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

class PostShimmer extends StatelessWidget {
  const PostShimmer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShimmerWidget(
      child: Column(
        children: [
          ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              focusColor: Colors.grey,
              hoverColor: Colors.grey,
              enableFeedback: true,
              leading: MatrixImageAvatar(
                  url: null,
                  fit: true,
                  backgroundColor: Theme.of(context).primaryColor,
                  width: 42,
                  height: 42,
                  client: null),
              title: Row(
                children: [
                  Container(
                    width: 120.0,
                    height: 10.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Row(
                  children: [
                    Container(
                      width: 90,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ],
                ),
              )),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20.0),
            child: Column(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const CircleAvatar(radius: 10),
              const SizedBox(width: 4),
              Container(
                height: 12,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 18),
              const CircleAvatar(radius: 10),
              const SizedBox(width: 4),
              Container(
                height: 12,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
