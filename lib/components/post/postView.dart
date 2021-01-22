import 'package:emoji_picker/emoji_picker.dart';
import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/matrix/mMessageDisplay.dart';
import 'package:minestrix/components/post/postHeader.dart';
import 'package:minestrix/components/post/postReactions.dart';
import 'package:minestrix/components/post/postReplies.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';

class Post extends StatefulWidget {
  final Event event;
  Post({Key key, @required this.event}) : super(key: key);

  @override
  _PostState createState() => _PostState();
}

class PostContent extends StatelessWidget {
  final Event event;
  const PostContent(
    this.event, {
    Key key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            MessageDisplay(event: event),
          ]),
    );
  }
}

class _PostState extends State<Post> with SingleTickerProviderStateMixin {
  bool showReplyBox = false;

  Future<void> pickEmoji(Event e) async {
    Emoji emoji = await showModalBottomSheet(
        context: context,
        builder: (context) => Column(children: [
              EmojiPicker(
                onEmojiSelected: (emoji, category) {
                  Navigator.of(context).pop<Emoji>(emoji);
                },
              ),
            ]));
    await e.room.sendReaction(e.eventId, emoji.emoji);
  }

  @override
  Widget build(BuildContext context) {
    Event e = widget.event;
    SClient sclient = Matrix.of(context).sclient;

    Timeline t = sclient.srooms[e.roomId].timeline;

    return StreamBuilder<Object>(
        stream: e.room.onUpdate.stream,
        builder: (context, snapshot) {
          Set<Event> replies = e.aggregatedEvents(t, RelationshipTypes.Reply);
          Set<Event> reactions =
              e.aggregatedEvents(t, RelationshipTypes.Reaction);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // post content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PostHeader(event: e),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 10),
                      child: PostContent(e),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Row(
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(primary: Colors.black),
                            onPressed: () async {
                              await pickEmoji(e);
                            },
                            child: reactions.isNotEmpty
                                ? PostReactions(event: e, reactions: reactions)
                                : ReactionItemWidget(
                                    Row(children: [
                                      Icon(Icons.emoji_emotions, size: 16),
                                      SizedBox(width: 10),
                                      Text("0")
                                    ]),
                                  ),
                          ),
                          SizedBox(width: 10),
                          TextButton(
                            onPressed: replyButtonClick,
                            style: TextButton.styleFrom(primary: Colors.black),
                            child: ReactionItemWidget(
                              Row(children: [
                                Icon(Icons.reply, size: 16),
                                SizedBox(width: 10),
                                Text("")
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  //color: Color(0xfff6f6f6),
                  child: Column(
                    children: [
                      if (showReplyBox) ReplyBox(event: e),
                      if (replies.isNotEmpty)
                        RepliesVue(event: e, replies: replies),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  void replyButtonClick() {
    setState(() {
      showReplyBox = !showReplyBox;
    });
  }
}
