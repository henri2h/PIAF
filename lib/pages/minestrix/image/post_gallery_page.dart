import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/event/matrix_image.dart';
import 'package:minestrix_chat/utils/social/posts/model/json/social_image_item.dart';
import 'package:minestrix_chat/utils/social/posts/model/social_item.dart';
import 'package:minestrix_chat/utils/social/posts/posts_event_extension.dart';

import '../../../partials/post/details/post_replies.dart';
import '../../../partials/post/gallery/post_gallery_nav_button.dart';
import '../../../partials/post/details/post_header.dart';

class PostGalleryPage extends StatefulWidget {
  final SocialItem post;
  final SocialImageItem? image;
  final String? selectedImageEventId;
  const PostGalleryPage(
      {Key? key, required this.post, this.image, this.selectedImageEventId})
      : assert(image == null || selectedImageEventId == null),
        super(key: key);

  @override
  State<PostGalleryPage> createState() => _PostGalleryPageState();
}

class _PostGalleryPageState extends State<PostGalleryPage> {
  bool get modeRef => widget.selectedImageEventId != null;
  Timeline? timeline;

  Set<Event>? reactions;
  Set<Event>? replies;
  Map<Event, dynamic>? nestedReplies;

  String? _replyToMessageId = null;
  String? get replyToMessageId =>
      _replyToMessageId ??
      (modeRef ? selectedImageEventId : widget.post.event?.eventId);
  Event? get event => modeRef ? _event : widget.post.event;

  Future<Timeline> getTimeline() async {
    if (timeline != null) return timeline!;
    timeline = await widget.post.event?.room.getTimeline(onUpdate: () {
      if (timeline != null) {
        loadPost(timeline!);
        if (mounted) setState(() {});
      }
    });

    loadPost(timeline!);
    return timeline!;
  }

  void loadPost(Timeline t) {
    reactions = event?.getReactions(t);
    replies = event?.getReplies(t);
    if (replies != null) nestedReplies = event?.getNestedReplies(replies!);
  }

  void setRepliedMessage(String? value) => setState(() {
        _replyToMessageId = value;
      });

  String? selectedImageEventId;
  SocialImageItem? selectedImage;
  Event? _event;
  Future<SocialImageItem?>? futureImage;
  Future<SocialImageItem?> getImage() async {
    if (selectedImage != null) return selectedImage;

    if (selectedImageEventId != null) {
      _event =
          await widget.post.event!.room.getEventById(selectedImageEventId!);
      if (_event != null) {
        if (timeline != null) loadPost(timeline!);
        return SocialImageItem.fromJson(_event!.content);
      }
    }

    return null;
  }

  @override
  void initState() {
    selectedImage = widget.image;
    selectedImageEventId = widget.selectedImageEventId;

    futureImage = getImage();

    super.initState();
  }

  void selectImage(int pos) {
    if (!modeRef) {
      selectedImage = widget.post.images[pos];
    } else {
      selectedImageEventId = widget.post.imagesRefEventId[pos];
      _replyToMessageId = null;
    }
    futureImage = getImage();
    setState(() {});
  }

  int get imgCount => selectedImage != null
      ? widget.post.images.length
      : widget.post.imagesRefEventId.length;

  int get pos => selectedImage != null
      ? widget.post.images.indexOf(selectedImage!)
      : widget.post.imagesRefEventId.indexOf(selectedImageEventId!);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SocialImageItem?>(
        future: futureImage,
        builder: (context, snap) {
          return LayoutBuilder(builder: (context, constraints) {
            return Row(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    fit: StackFit.expand,
                    children: [
                      Builder(builder: (context) {
                        if (!snap.hasData)
                          return Center(child: CircularProgressIndicator());
                        final image = snap.data!;

                        return MatrixSocialImage(
                            key: Key(image.file?.url ?? pos.toString()),
                            room: widget.post.event!.room,
                            image: image,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.zero);
                      }),
                      PostGalleryNavButton(
                          alignment: Alignment.centerLeft,
                          icon: Icons.keyboard_arrow_left,
                          onPressed: pos > 0
                              ? () => selectImage(pos - 1)
                              : () => null),
                      PostGalleryNavButton(
                          alignment: Alignment.centerRight,
                          icon: Icons.keyboard_arrow_right,
                          onPressed: (pos + 1) < imgCount
                              ? () => selectImage(pos + 1)
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
                            (pos + 1).toString() + "/" + imgCount.toString(),
                            style: TextStyle(
                                fontSize: 26,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ))
                    ],
                  ),
                ),
                if (constraints.maxWidth > 1000)
                  FutureBuilder<Timeline>(
                      future: getTimeline(),
                      builder: (context, snapshot) {
                        final t = snapshot.data;
                        return SizedBox(
                            width: 340,
                            child: ListView(
                              children: [
                                PostHeader(
                                    event: widget.post.event!,
                                    allowContext: false),
                                if (event != null)
                                  RepliesVue(
                                      timeline: t,
                                      enableMore: false,
                                      event: event!,
                                      replies: nestedReplies,
                                      replyToMessageId: replyToMessageId,
                                      setRepliedMessage: setRepliedMessage),
                              ],
                            ));
                      }),
              ],
            );
          });
        });
  }
}
