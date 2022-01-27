import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/minestrixTitle.dart';
import 'package:minestrix/partials/post/postView.dart';
import 'package:minestrix_chat/config/extensible_types.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/event/matrix_image.dart';
import 'package:minestrix_chat/partials/matrix_images.dart';

class PostContent extends StatelessWidget {
  final String regex =
      "(>(.*)\n)*\n"; // TODO : find a better way to remove the formated body

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
        return MatrixPost(
            event: event,
            imageMaxHeight: imageMaxHeight,
            imageMaxWidth: imageMaxWidth);
      case EventTypes.Encrypted:
        switch (event.messageType) {
          case MessageTypes.Text:
          case MessageTypes.Emote:
            return MarkdownBody(
              data: event.body.replaceFirst(new RegExp(regex), ""),
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
        update = Text("Display name update");

        break;
      case PostTypeUpdate.ProfilePicture:
        update = Text("Profile picture update");

        break;
      case PostTypeUpdate.Membership:
        update = Text("Joined");

        break;
      default:
        update = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Default : "),
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

class MatrixPost extends StatelessWidget {
  final double? imageMaxHeight;
  final double? imageMaxWidth;
  const MatrixPost(
      {Key? key, required this.event, this.imageMaxHeight, this.imageMaxWidth})
      : super(key: key);

  final Event event;

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> items = [];
    if (event.content[MatrixTypes.post] is List<dynamic>) {
      items = [...event.content[MatrixTypes.post]];
    } else if (event.content[MatrixTypes.post] is Map<String, dynamic>) {
      items.add(event.content[MatrixTypes.post]);
    }

    return Column(
      children: [
        for (Map<String, dynamic> item in items)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item[ExtensibleTypes.text] != null)
                MarkdownBody(
                  data: item[ExtensibleTypes.text],
                ),
              if (item[ExtensibleTypes.file] is Map) // There is a
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: imageMaxHeight != null
                        ? ConstrainedBox(
                            constraints: BoxConstraints(
                                maxHeight: imageMaxHeight!,
                                minHeight: imageMaxHeight ?? 400),
                            child: MatrixImageViewever(event: event, map: item))
                        : MatrixImageViewever(event: event, map: item))
            ],
          ),
      ],
    );
  }
}
