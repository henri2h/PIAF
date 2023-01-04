import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/event/matrix_image.dart';
import 'package:minestrix_chat/utils/social/posts/model/social_item.dart';
import 'package:minestrix_chat/utils/social/posts/posts_event_extension.dart';

import '../../../partials/post/details/post_replies.dart';
import '../../../partials/post/gallery/post_gallery_nav_button.dart';
import '../../../partials/post/details/post_header.dart';

class PostGalleryPage extends StatefulWidget {
  final Event post;
  final Event? image;
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

  String? _replyToMessageId;
  String? get replyToMessageId =>
      _replyToMessageId ??
      (modeRef ? selectedImageEventId : widget.post.eventId);
  Event? get event => modeRef ? _event : widget.post;

  Future<Timeline> getTimeline() async {
    if (timeline != null) return timeline!;
    timeline = await widget.post.room.getTimeline(onUpdate: () {
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
  Event? selectedImage;
  Event? _event;
  Future<Event?>? futureImage;
  Future<Event?> getImage() async {
    if (selectedImage != null) return selectedImage;

    if (selectedImageEventId != null) {
      _event = await widget.post.room.getEventById(selectedImageEventId!);
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
      selectedImage = widget.image;
    } else {
      selectedImageEventId = widget.post.imagesRefEventId[pos];
      _replyToMessageId = null;
    }
    futureImage = getImage();
    setState(() {});
  }

  int get imgCount => widget.post.imagesRefEventId.length;
  int get pos => widget.post.imagesRefEventId.indexOf(selectedImageEventId!);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Event?>(
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
                        if (!snap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final image = snap.data!;

                        return MatrixEventImage(
                          key: Key(image.eventId),
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.zero,
                          event: widget.post,
                        );
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
                                child: const Icon(Icons.close,
                                    size: 40, color: Colors.white),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                })),
                      Positioned(
                          bottom: 12,
                          right: 12,
                          child: Text(
                            "${pos + 1}/$imgCount",
                            style: const TextStyle(
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
                                    event: widget.post, allowContext: false),
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
