import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/post/postHeader.dart';
import 'package:minestrix/components/post/postReactions.dart';
import 'package:minestrix/components/post/postReplies.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix_chat/partials/matrix_images.dart';
import 'package:minestrix_chat/partials/matrix_messeage.dart';

class Post extends StatefulWidget {
  final Event event;
  Post({Key? key, required this.event}) : super(key: key);

  @override
  _PostState createState() => _PostState();
}

class PostContent extends StatelessWidget {
  final Event event;
  const PostContent(
    this.event, {
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    switch (event.type) {
      case EventTypes.Message:
      case EventTypes.Encrypted:
        switch (event.messageType) {
          case MessageTypes.Text:
          case MessageTypes.Emote:
            return MarkdownBody(
              data: event.body,
            );

          case MessageTypes.Image:
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarkdownBody(data: event.body),
                const SizedBox(height: 10),
                MImage(event: event),
              ],
            );
          case MessageTypes.Video:
            return Text(event.body);

          default:
            return Text("other message type : " + event.messageType);
        }
    }
    return Container(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            MessageDisplay(client: Matrix.of(context).sclient, event: event),
          ]),
    );
  }
}

class _PostState extends State<Post> with SingleTickerProviderStateMixin {
  bool showReplyBox = false;

  Future<void> pickEmoji(Event e) async {
    Emoji? emoji = await showModalBottomSheet(
        context: context,
        builder: (context) => SizedBox(
              height: 140,
              child: EmojiPicker(
                onEmojiSelected: (Category category, Emoji emoji) {
                  Navigator.of(context).pop<Emoji>(emoji);
                },
                config: Config(
                  columns: 25,
                ),
              ),
            ));
    if (emoji != null) await e.room.sendReaction(e.eventId, emoji.emoji);
  }

  @override
  Widget build(BuildContext context) {
    Event e = widget.event;
    MinestrixClient sclient = Matrix.of(context).sclient!;

    Timeline? t = sclient.srooms[e.roomId!]!.timeline;
    return StreamBuilder<Object>(
        stream: e.room.onUpdate.stream,
        builder: (context, snapshot) {
          Set<Event> replies = e.aggregatedEvents(t!, RelationshipTypes.reply);
          Set<Event> reactions =
              e.aggregatedEvents(t, RelationshipTypes.reaction);
          return Card(
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
                      Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (reactions.isNotEmpty)
                              Expanded(
                                child: MaterialButton(
                                    onPressed: () async {
                                      await pickEmoji(e);
                                    },
                                    child: PostReactions(
                                        event: e, reactions: reactions)),
                              ),
                            if (reactions.isEmpty)
                              Expanded(
                                child: MaterialButton(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.emoji_emotions),
                                      SizedBox(width: 10),
                                      Flexible(child: Text("React"))
                                    ],
                                  ),
                                  onPressed: () async {
                                    await pickEmoji(e);
                                  },
                                ),
                              ),
                            SizedBox(width: 10),
                            Expanded(
                              child: MaterialButton(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.reply),
                                    SizedBox(width: 10),
                                    Flexible(child: Text("Comment"))
                                  ],
                                ),
                                onPressed: replyButtonClick,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  Container(
                    //color: Color(0xfff6f6f6),
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
