import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/post/postDetails/postContent.dart';
import 'package:minestrix/partials/post/postDetails/postHeader.dart';
import 'package:minestrix/partials/post/postDetails/postReactions.dart';
import 'package:minestrix/partials/post/postDetails/postReplies.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/matrix/reactions_list.dart';

class Post extends StatefulWidget {
  final Event event;
  final void Function(Offset) onReact;
  final Timeline? timeline;
  Post({Key? key, required this.event, required this.onReact, this.timeline})
      : super(key: key);

  @override
  _PostState createState() => _PostState();
}

enum PostTypeUpdate { ProfilePicture, DisplayName, Membership, None }

class _PostState extends State<Post> with SingleTickerProviderStateMixin {
  final key = GlobalKey();
  bool showReplyBox = false;
  bool showReplies = true;

  late Future<Timeline> futureTimeline;

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
    Event e = widget.event;

    return FutureBuilder<Timeline?>(
        future: futureTimeline,
        builder: (context, snap) {
          Timeline? t = snap.data;

          return StreamBuilder<Object>(
              stream: e.room.onUpdate.stream,
              builder: (context, snapshot) {
                // support for threaded replies

                Set<Event>? reactions;
                Set<Event>? replies;

                if (t != null) {
                  replies =
                      e.aggregatedEvents(t, MatrixTypes.elementThreadEventType);

                  // TODO: remove me, this was when replies as thread was not supported
                  replies
                      .addAll(e.aggregatedEvents(t, RelationshipTypes.reply));
                  reactions = e.aggregatedEvents(t, RelationshipTypes.reaction);
                }
                return Card(
                  key: key,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // post content
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PostHeader(event: e),
                          PostContent(
                            e,
                            imageMaxHeight: 300,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      if (reactions?.isNotEmpty ?? false)
                                        Flexible(
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      horizontal: 8.0),
                                                  child: MaterialButton(
                                                      child: PostReactions(
                                                          event: e,
                                                          reactions:
                                                              reactions!),
                                                      onPressed: () async {
                                                        await showDialog(
                                                            context: context,
                                                            builder: (context) =>
                                                                Dialog(
                                                                    child:
                                                                        ConstrainedBox(
                                                                  constraints: BoxConstraints(
                                                                      maxWidth:
                                                                          600,
                                                                      maxHeight:
                                                                          600),
                                                                  child: EventReactionList(
                                                                      reactions:
                                                                          reactions!),
                                                                )));
                                                      }),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      if (replies?.isNotEmpty ?? false)
                                        MaterialButton(
                                            child: Text((showReplies
                                                    ? "Hide "
                                                    : "Show ") +
                                                replies!.length.toString() +
                                                " comments"),
                                            onPressed: () {
                                              setState(() {
                                                showReplies = !showReplies;
                                              });
                                            }),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  child: MaterialButton(
                                      elevation: 0,
                                      color: Theme.of(context).primaryColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 2),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.insert_emoticon_rounded,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary),
                                          SizedBox(width: 5),
                                          Text("Reaction",
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary))
                                        ],
                                      ),
                                      onPressed: () {}),
                                  onTapDown: (TapDownDetails detail) async {
                                    widget.onReact(detail.globalPosition);
                                  },
                                ),
                                SizedBox(width: 9),
                                MaterialButton(
                                  elevation: 0,
                                  color: Theme.of(context).primaryColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.reply,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary),
                                      SizedBox(width: 5),
                                      Text("Comment",
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary))
                                    ],
                                  ),
                                  onPressed: replyButtonClick,
                                ),
                              ],
                            ),
                          )
                        ],
                      ),

                      ((replies?.isNotEmpty ?? false) && showReplies ||
                              showReplyBox)
                          ? Divider()
                          : SizedBox(height: 8),
                      if (showReplies)
                        Container(
                          child: Column(
                            children: [
                              if (((replies?.isNotEmpty ?? false) ||
                                      showReplyBox) &&
                                  t != null)
                                RepliesVue(
                                    timeline: t,
                                    event: e,
                                    replies: replies ?? Set<Event>(),
                                    showEditBox: showReplyBox,
                                    setReplyVisibility: (bool value) =>
                                        setState(() {
                                          showReplyBox = value;
                                        })),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              });
        });
  }

  void replyButtonClick() {
    setState(() {
      showReplyBox = !showReplyBox;
    });
  }
}
