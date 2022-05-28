import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/minestrixTitle.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/feed/posts/matrix_post_content.dart';
import 'package:minestrix_chat/partials/matrix_images.dart';

class PostContent extends StatelessWidget {
  final Event event;
  final double? imageMaxHeight;
  final double? imageMaxWidth;
  final bool disablePadding;
  const PostContent(this.event,
      {Key? key,
      this.imageMaxHeight,
      this.imageMaxWidth,
      this.disablePadding = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (event.type) {
      case EventTypes.Encrypted:
      case MatrixTypes.post:
        return MatrixPostContent(
            event: event,
            imageMaxHeight: imageMaxHeight,
            imageMaxWidth: imageMaxWidth,
            disablePadding: disablePadding,
            onImagePressed: (image, post) {
              context.pushRoute(PostGalleryRoute(image: image, post: post));
            });

      case EventTypes.Message:
        switch (event.messageType) {
          case MessageTypes.Text:
          case MessageTypes.Emote:
            return MarkdownBody(
              data: event.getLocalizedBody(const MatrixDefaultLocalizations()),
            );

          case MessageTypes.Image:
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarkdownBody(data: event.body),
                const SizedBox(height: 10),
                imageMaxHeight != null
                    ? ConstrainedBox(
                        constraints: BoxConstraints(
                            maxHeight: imageMaxHeight!,
                            minHeight: imageMaxHeight ?? 400),
                        child: MImage(event: event))
                    : MImage(event: event),
              ],
            );
          case MessageTypes.Video:
            return Text(event.body);

          default:
            return Text("other message type : " + event.type);
        }
      case EventTypes.RoomCreate:
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                  "✨ " + event.sender.calcDisplayname() + " Joined MinesTRIX ✨",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400)),
            ),
            MinestrixTitle()
          ],
        );

      case EventTypes.RoomAvatar:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                  event.sender.calcDisplayname() + " Changed page picture",
                  style: TextStyle()),
            ),
            MImage(event: event),
          ],
        );
    }

    return Container(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(event.type),
          ]),
    );
  }
}
