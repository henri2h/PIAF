import 'package:flutter/material.dart';
import 'package:minestrix_chat/partials/event/matrix_image.dart';
import 'package:minestrix_chat/utils/social/posts/model/json/social_image_item.dart';
import 'package:minestrix_chat/utils/social/posts/model/social_item.dart';

import '../../../partials/post/gallery/post_gallery_nav_button.dart';
import '../../../partials/post/postDetails/postHeader.dart';

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
  @override
  void initState() {
    image = widget.image;
    super.initState();
  }

  int get pos => widget.post.images.indexOf(image);
  @override
  Widget build(BuildContext context) {
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
                    child: IconButton(
                        icon: Icon(Icons.close, size: 40, color: Colors.white),
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
        SizedBox(
            width: 340,
            child: ListView(
              children: [
                PostHeader(event: widget.post.event!),
              ],
            )),
      ],
    );
  }
}
