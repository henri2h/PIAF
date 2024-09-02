import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/app_title.dart';
import 'package:piaf/router.gr.dart';
import 'package:piaf/config/matrix_types.dart';
import 'package:piaf/partials/chat/event/event_types/room_message/bubles/message/matrix_video_message.dart';
import 'package:piaf/partials/event/matrix_image.dart';
import 'package:piaf/partials/chat_feed/posts/matrix_post_content.dart';

class PostContent extends StatelessWidget {
  final Event event;
  final double? imageMaxHeight;
  final double? imageMaxWidth;
  final bool disablePadding;
  const PostContent(this.event,
      {super.key,
      this.imageMaxHeight,
      this.imageMaxWidth,
      this.disablePadding = false});

  @override
  Widget build(BuildContext context) {
    switch (event.type) {
      case EventTypes.Encrypted:
      case MatrixTypes.post:
      case MatrixTypes.comment:
        return MatrixPostContent(
            event: event,
            imageMaxHeight: imageMaxHeight,
            imageMaxWidth: imageMaxWidth,
            disablePadding: disablePadding,
            onImagePressed: (Event post, {Event? imageEvent, String? ref}) {
              context.pushRoute(PostGalleryRoute(
                  image: imageEvent, post: post, selectedImageEventId: ref));
            });

      case EventTypes.Message:
        switch (event.messageType) {
          case MessageTypes.Text:
          case MessageTypes.Emote:
            return FutureBuilder<String>(
                future:
                    event.calcLocalizedBody(const MatrixDefaultLocalizations()),
                builder: (context, snap) {
                  final text = snap.data ?? event.body;
                  return MarkdownBody(
                    data: text,
                  );
                });

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
                        child: MatrixImage(event: event))
                    : MatrixImage(event: event),
              ],
            );
          case MessageTypes.Video:
            return MatrixVideoMessage(event);

          default:
            return Text("other message type : ${event.type}");
        }
      case EventTypes.RoomCreate:
        return FutureBuilder<User?>(
            future: event.fetchSenderUser(),
            builder: (context, snap) {
              final sender = snap.data ?? event.senderFromMemoryOrFallback;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                        "✨ ${sender.calcDisplayname()} created ${event.room.getLocalizedDisplayname()} ✨",
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w400)),
                  ),
                  const AppTitle()
                ],
              );
            });

      case EventTypes.RoomAvatar:
        return FutureBuilder<User?>(
            future: event.fetchSenderUser(),
            builder: (context, snap) {
              final sender = snap.data ?? event.senderFromMemoryOrFallback;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                        "${sender.calcDisplayname()} Changed page picture",
                        style: const TextStyle()),
                  ),
                  MatrixImage(event: event),
                ],
              );
            });
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(event.type),
        ]);
  }
}
