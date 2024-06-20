import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/chat_feed/posts/matrix_post_image_container.dart';

import '../../utils/extensions/minestrix/model/social_item.dart';

class MatrixPostContent extends StatelessWidget {
  final double? imageMaxHeight;
  final double? imageMaxWidth;
  final bool disablePadding;
  final Function(Event, {Event? imageEvent, String? ref}) onImagePressed;
  const MatrixPostContent(
      {super.key,
      required this.event,
      this.imageMaxHeight,
      this.imageMaxWidth,
      this.disablePadding = false,
      required this.onImagePressed});

  final Event event;

  @override
  Widget build(BuildContext context) {
    if (event.redacted) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.delete_forever, color: Colors.red),
          SizedBox(width: 10),
          Flexible(
              child: Text("Post redacted", style: TextStyle(color: Colors.red)))
        ]),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.messageType == MessageTypes.BadEncrypted)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.lock_clock,
                        color: Theme.of(context).colorScheme.onSurface),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Post encrypted",
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface)),
                          Text(
                              "Waiting for encryption key, it may take a while",
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 12))
                        ],
                      ),
                    )
                  ]),
                ),
              if (event.imagesRefEventId.isNotEmpty)
                LayoutBuilder(builder: (context, constraints) {
                  // display single or double image smaller than 3
                  final imageLen = event.imagesRefEventId.length;
                  double coeff = 0.5;
                  if (imageLen > 2) {
                    coeff = 0.7;
                  }

                  return ConstrainedBox(
                    constraints:
                        BoxConstraints(maxHeight: constraints.maxWidth * coeff),
                    child: ImagePreview(
                        post: event,
                        imageMaxHeight: imageMaxHeight,
                        imageMaxWidth: imageMaxWidth,
                        onImagePressed: onImagePressed),
                  );
                }),
              if (event.body.isNotEmpty)
                Padding(
                  padding: disablePadding
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 8),
                  child: MarkdownBody(
                    data: event.body,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class ImagePreview extends StatelessWidget {
  final Event post;
  final double? imageMaxHeight;
  final double? imageMaxWidth;

  final Function(Event, {Event? imageEvent, String? ref}) onImagePressed;

  const ImagePreview(
      {super.key,
      required this.post,
      required this.imageMaxHeight,
      required this.imageMaxWidth,
      required this.onImagePressed});

  String? getRef(int pos) {
    if (post.imagesRefEventId.length > pos) return post.imagesRefEventId[pos];
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final imageLen = post.imagesRefEventId.length;

    if (imageLen == 1) {
      return Stack(
        fit: StackFit.expand,
        children: [
          MatrixPostImageContainer(
              imageMaxHeight: imageMaxHeight,
              post: post,
              imageRef: getRef(0),
              onPressed: onImagePressed),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: MatrixPostImageContainer(
                    imageMaxHeight: imageMaxHeight,
                    post: post,
                    imageRef: getRef(0),
                    onPressed: onImagePressed),
              ),
              if (imageLen > 2)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: MatrixPostImageContainer(
                        imageMaxHeight: imageMaxHeight,
                        post: post,
                        imageRef: getRef(2),
                        onPressed: onImagePressed),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 3),
            child: MatrixPostImageContainer(
                imageMaxHeight: imageMaxHeight,
                post: post,
                imageRef: getRef(1),
                text: imageLen > 3 ? "+${imageLen - 3}" : null,
                onPressed: onImagePressed),
          ),
        ),
      ],
    );
  }
}
