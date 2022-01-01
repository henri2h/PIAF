import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/post/postDetails/postContent.dart';
import 'package:minestrix/components/post/postDetails/postHeader.dart';
import 'package:minestrix/components/post/postDetails/postReactions.dart';
import 'package:minestrix/components/post/postDetails/postReplies.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';

class Post extends StatefulWidget {
  final Event event;
  final void Function(TapDownDetails) onReact;
  Post({Key? key, required this.event, required this.onReact})
      : super(key: key);

  @override
  _PostState createState() => _PostState();
}

enum PostTypeUpdate { ProfilePicture, DisplayName, Membership, None }

class _PostState extends State<Post> with SingleTickerProviderStateMixin {
  final key = GlobalKey();
  bool showReplyBox = false;

/*  Future<void> pickEmoji(TapDownDetails detail, Event e) async {
    print(detail.globalPosition.dx.toString());
    print(detail.globalPosition.dy.toString());
    double paddingLeft = detail.globalPosition.dx;
    double paddingTop =
        detail.globalPosition.dy + 30; // + 30 in order to be under the button

    double width = min(MediaQuery.of(context).size.width, 400);
    double height = min(MediaQuery.of(context).size.height, 180);

    if ((MediaQuery.of(context).size.width - paddingLeft) < width)
      paddingLeft = MediaQuery.of(context).size.width - width;
    if ((MediaQuery.of(context).size.height - paddingTop) < height)
      paddingTop = MediaQuery.of(context).size.height - height;

    Emoji? emoji = await showDialog<Emoji>(
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(top: paddingTop, left: paddingLeft),
          child: MinestrixEmojiPicker(height: height, width: width),
        );
      },
    );

    if (emoji != null) await e.room.sendReaction(e.eventId, emoji.emoji);
  }*/

  @override
  Widget build(BuildContext context) {
    Event e = widget.event;
    MinestrixClient sclient = Matrix.of(context).sclient!;

    Timeline? t = sclient.srooms[e.roomId!]?.timeline;
    if (t == null) {
      return CircularProgressIndicator();
    }

    return StreamBuilder<Object>(
        stream: e.room.onUpdate.stream,
        builder: (context, snapshot) {
          Set<Event> replies = e.aggregatedEvents(t, RelationshipTypes.reply);
          Set<Event> reactions =
              e.aggregatedEvents(t, RelationshipTypes.reaction);
          return Card(
            key: key,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
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
                          child: PostContent(e)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4.0, vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (reactions.isNotEmpty)
                              Flexible(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: MaterialButton(
                                            child: PostReactions(
                                                event: e, reactions: reactions),
                                            onPressed: () {}),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              child: MaterialButton(
                                  elevation: 0,
                                  color: Color(0xFF323232),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.insert_emoticon_rounded),
                                      SizedBox(width: 5),
                                      Text("Reaction")
                                    ],
                                  ),
                                  onPressed: () {}),
                              onTapDown: (TapDownDetails detail) async {
                                widget.onReact(detail);
                              },
                            ),
                            SizedBox(width: 9),
                            MaterialButton(
                              elevation: 0,
                              color: Color(0xFF323232),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.reply),
                                  SizedBox(width: 5),
                                  Text("Comment")
                                ],
                              ),
                              onPressed: replyButtonClick,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),

                  if (replies.isNotEmpty || showReplyBox) Divider(),
                  Container(
                    child: Column(
                      children: [
                        if (replies.isNotEmpty || showReplyBox)
                          RepliesVue(
                              event: e,
                              replies: replies,
                              showEditBox: showReplyBox),
                      ],
                    ),
                  ),
                ],
              ),
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
