import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/partials/feed/posts/matrix_post_editor.dart';
import 'package:minestrix_chat/utils/extensions/minestrix/model/social_item.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../../../router.gr.dart';
import '../../../utils/settings.dart';
import 'content/post_content.dart';
import 'content/post_header.dart';
import 'content/post_reaction_bar.dart';

class PostItem extends StatefulWidget {
  final Event event;
  final void Function(Offset) onReact;
  final Timeline? timeline;
  final bool isMobile;
  final bool enableComment;

  const PostItem(
      {super.key,
      required this.event,
      required this.onReact,
      required this.timeline,
      required this.isMobile,
      this.enableComment = true});

  @override
  PostItemState createState() => PostItemState();
}

enum PostTypeUpdate { profilePicture, displayName, membership, none }

class PostItemState extends State<PostItem>
    with SingleTickerProviderStateMixin {
  final key = GlobalKey();
  bool showReplies = false;

  Future<Event?>? shareEvent;

  bool get canShare =>
      Settings().shareEnabled &&
      widget.event.room.historyVisibility == HistoryVisibility.worldReadable &&
      widget.event.room.client.minestrixUserRoom.isNotEmpty;

  late Event post;

  bool get canComment => widget.enableComment;

  @override
  void initState() {
    post = widget.event;

    if (post.shareEventId != null && post.shareEventRoomId != null) {
      shareEvent = widget.event.room.client.getEventFromArbitraryRoomById(
          post.shareEventId!, post.shareEventRoomId!);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final timeline = widget.timeline;

    final displayEvent = timeline != null
        ? post.getDisplayEventWithType(timeline, MatrixTypes.post)
        : post;
    final reactions = timeline != null ? post.getReactions(timeline) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // post content
        if (widget.isMobile) const Divider(),
        PostHeader(eventToEdit: post, event: displayEvent),
        if (!widget.isMobile)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
            child: Divider(),
          ),
        if ([EventStatus.sent, EventStatus.synced].contains(post.status) ==
            false)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
                trailing: const Icon(Icons.message),
                leading: const CircularProgressIndicator(),
                title: const Text("Sending"),
                subtitle: Text(
                    post.status.toString().replaceAll("EventStatus.", ""))),
          ),
        PostContent(
          displayEvent,
          imageMaxHeight: 300,
        ),
        if (shareEvent != null)
          FutureBuilder<Event?>(
              future: shareEvent,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.error),
                        const SizedBox(width: 4),
                        Text(snap.error.toString()),
                      ],
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const CircularProgressIndicator();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Sharing"),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PostHeader(event: snap.data!, allowContext: false),
                            PostContent(
                              snap.data!,
                              imageMaxHeight: 300,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: ReactionBar(
            controller: this,
            isMobile: widget.isMobile,
            reactions: reactions,
          ),
        ),
      ],
    );
  }

  void replyButtonClick() {
    if (widget.timeline != null) {
      context.pushRoute(
          PostRoute(event: widget.event, timeline: widget.timeline!));
    }
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
