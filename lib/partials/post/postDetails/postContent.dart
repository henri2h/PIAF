import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/feed/posts/matrix_post_content.dart';
import 'package:minestrix_chat/partials/matrix_images.dart';
import 'package:minestrix_chat/utils/intl/matrix_translation_mock.dart';

import 'package:minestrix/partials/minestrixTitle.dart';
import 'package:minestrix/partials/post/postView.dart';
import 'package:minestrix/router.gr.dart';

class PostContent extends StatelessWidget {
  final Event event;
  final double? imageMaxHeight;
  final double? imageMaxWidth;
  const PostContent(this.event,
      {Key? key, this.imageMaxHeight, this.imageMaxWidth})
      : super(key: key);

  PostTypeUpdate getPostTypeUpdate(Event e) {
    if (e.prevContent?["avatar_url"] != null &&
        e.prevContent!["avatar_url"] != e.content["avatar_url"])
      return PostTypeUpdate.ProfilePicture;
    else if (e.prevContent?["displayname"] != null &&
        e.prevContent!["displayname"] != e.content["displayname"])
      return PostTypeUpdate.DisplayName;
    else if (e.prevContent?["membership"] != e.content["membership"])
      return PostTypeUpdate
          .Membership; // by default, if prevContent == null, the owner joined the room or was invited

    return PostTypeUpdate.None;
  }

  @override
  Widget build(BuildContext context) {
    switch (event.type) {
      case EventTypes.Encrypted:
      case MatrixTypes.post:
        return MatrixPostContent(
            event: event,
            imageMaxHeight: imageMaxHeight,
            imageMaxWidth: imageMaxWidth,
            onImagePressed: (image, post) {
              context.pushRoute(PostGalleryRoute(image: image, post: post));
            });
      case EventTypes.Encrypted:
        switch (event.messageType) {
          case MessageTypes.Text:
          case MessageTypes.Emote:
            return MarkdownBody(
              data: event.getLocalizedBody(MatrixLocals()),
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
    PostTypeUpdate pUp = getPostTypeUpdate(event);
    Widget update;
    switch (pUp) {
      case PostTypeUpdate.DisplayName:
        update = Text(
            "Display name update " + event.getLocalizedBody(MatrixLocals()));

        break;
      case PostTypeUpdate.ProfilePicture:
        update = Text(
            "Profile picture update " + event.getLocalizedBody(MatrixLocals()));

        break;
      case PostTypeUpdate.Membership:
        update = Text("Joined " + event.getLocalizedBody(MatrixLocals()));

        break;
      default:
        update = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Default : "),
            Text(event.getLocalizedBody(MatrixLocals())),
            Text(event.content.toString()),
            Text(event.prevContent.toString())
            /*
           // Debug :
            Text(event.content.toString()),
            SizedBox(height: 10),
            Text(event.prevContent.toString()),
            Text(event.toJson().toString())
            */
          ],
        );
    }
    return Container(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            update,
            Text(event.type),
          ]),
    );
  }
}
