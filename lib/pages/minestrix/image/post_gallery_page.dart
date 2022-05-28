import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/event/matrix_image.dart';
import 'package:minestrix_chat/utils/social/posts/model/json/social_image_item.dart';
import 'package:minestrix_chat/utils/social/posts/model/social_item.dart';

import '../../../partials/post/details/post_replies.dart';
import '../../../partials/post/gallery/post_gallery_nav_button.dart';
import '../../../partials/post/details/post_header.dart';

class PostGalleryPage extends StatefulWidget {
  final SocialImageItem image;
  final SocialItem post;
  const PostGalleryPage({Key? key, required this.post, required this.image})
      : super(key: key);

  @override
  State<PostGalleryPage> createState() => _PostGalleryPageState();
}

class _PostGalleryPageState extends State<PostGalleryPage> {
  late SocialImageItem image;
  Timeline? timeline;

  Set<Event>? reactions;
  Set<Event>? replies;
  Map<Event, dynamic>? nestedReplies;

  String? replyToMessageId = null;

  Future<Timeline> getTimeline() async {
    timeline = await widget.post.event?.room.getTimeline(onUpdate: () {
      if (timeline != null) {
        loadPost(timeline!);
        if (mounted) setState(() {});
      }
    });

    loadPost(timeline!); // TODO: hook load post to refresh
    return timeline!;
  }

  void loadPost(Timeline t) {
    reactions = widget.post.getReactions(t);
    replies = widget.post.getReplies(t);
    if (replies != null) nestedReplies = widget.post.getNestedReplies(replies!);
  }

  void setRepliedMessage(String? value) => setState(() {
        replyToMessageId = value ?? widget.post.event?.eventId;
      });

  @override
  void initState() {
    image = widget.image;
    replyToMessageId = widget.post.event?.eventId;
    super.initState();
  }

  int get pos => widget.post.images.indexOf(image);
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Timeline>(
        future: getTimeline(),
        builder: (context, snapshot) {
          final t = snapshot.data;
          return LayoutBuilder(builder: (context, constraints) {
            return Row(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    fit: StackFit.expand,
                    children: [
                      MatrixImage(
                          key: Key(image.file?.url ?? pos.toString()),
                          event: widget.post.event!,
                          image: image,
                          boxfit: BoxFit.cover,
                          borderRadius: BorderRadius.zero),
                      PostGalleryNavButton(
                          alignment: Alignment.centerLeft,
                          icon: Icons.keyboard_arrow_left,
                          onPressed: pos > 0
                              ? () => setState(() {
                                    image = widget.post.images[pos - 1];
                                  })
                              : () => null),
                      PostGalleryNavButton(
                          alignment: Alignment.centerRight,
                          icon: Icons.keyboard_arrow_right,
                          onPressed: (pos + 1) < widget.post.images.length
                              ? () => setState(() {
                                    image = widget.post.images[pos + 1];
                                  })
                              : () => null),
                      if (Navigator.of(context).canPop())
                        Positioned(
                            top: 8,
                            right: 8,
                            child: MaterialButton(
                                minWidth: 0,
                                child: Icon(Icons.close,
                                    size: 40, color: Colors.white),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                })),
                      Positioned(
                          bottom: 12,
                          right: 12,
                          child: Text(
                            (pos + 1).toString() +
                                "/" +
                                widget.post.images.length.toString(),
                            style: TextStyle(
                                fontSize: 26,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ))
                    ],
                  ),
                ),
                if (constraints.maxWidth > 1000)
                  SizedBox(
                      width: 340,
                      child: ListView(
                        children: [
                          PostHeader(event: widget.post.event!),
                          if (t != null)
                            RepliesVue(
                                timeline: t,
                                event: widget.post.event!,
                                postEvent: widget.post.event!,
                                replies: nestedReplies,
                                replyToMessageId: replyToMessageId,
                                setRepliedMessage: setRepliedMessage),
                        ],
                      )),
              ],
            );
          });
        });
  }
}
