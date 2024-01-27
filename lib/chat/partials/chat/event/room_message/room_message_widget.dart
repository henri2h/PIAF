import 'dart:math';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/chat/minestrix_chat.dart';
import 'package:minestrix/chat/utils/l10n/event_localisation_extension.dart';

import '../../../dialogs/adaptative_dialogs.dart';
import '../../../matrix/matrix_image_avatar.dart';
import '../../../matrix/reactions_list.dart';
import '../../user/user_info_dialog.dart';
import 'bubles/buble.dart';
import '../event_widget.dart';

class RoomMessageWidget extends StatelessWidget {
  const RoomMessageWidget({
    super.key,
    required this.widget,
    required this.event,
  });

  final EventWidget widget;
  final Event event;

  Future<void> displayReactionDialog(BuildContext context) async {
    if (widget.reactions == null) return;
    await AdaptativeDialogs.show(
      context: context,
      title: "Reactions",
      builder: (context) => EventReactionList(reactions: widget.reactions!),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String?, int> keys = <String?, int>{};
    if (widget.reactions != null) {
      for (Event revent in widget.reactions!) {
        String? key = revent.content
            .tryGetMap<String, dynamic>('m.relates_to')
            ?.tryGet<String>('key');
        if (key != null) {
          keys.update(key, (value) => value + 1, ifAbsent: () => 1);
        }
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!event.sentByUser)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2.0, right: 10),
            child: SizedBox(
              width: 40,
              child: widget.displayAvatar
                  ? MaterialButton(
                      onPressed: () async {
                        await UserInfoDialog.show(
                            user: event.senderFromMemoryOrFallback,
                            context: context);
                      },
                      minWidth: 0,
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                      child: MatrixImageAvatar(
                          url: event.senderFromMemoryOrFallback.avatarUrl,
                          defaultText: event.senderFromMemoryOrFallback
                              .calcDisplayname(),
                          width: MinestrixAvatarSizeConstants.small,
                          height: MinestrixAvatarSizeConstants.small,
                          fit: true,
                          client: widget.client),
                    )
                  : null,
            ),
          ),
        FutureBuilder<Event?>(future: () async {
          if (widget.timeline != null &&
              event.relationshipType == RelationshipTypes.reply) {
            return event.getReplyEvent(widget.timeline!);
          }

          return null;
        }(), builder: (context, snapReplyEvent) {
          return Expanded(
            child: Column(
              crossAxisAlignment: event.sentByUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!event.sentByUser && widget.displayName ||
                    snapReplyEvent.hasData)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Wrap(
                      children: [
                        snapReplyEvent.hasData
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.reply, size: 18),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                          "${event.senderLocalisedDisplayName} relpied to ${snapReplyEvent.data!.senderLocalisedDisplayName}",
                                          maxLines: 2,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              )
                            : Text(
                                event.senderFromMemoryOrFallback
                                    .calcDisplayname(),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color)),
                      ],
                    ),
                  ),
                GestureDetector(
                  onLongPressStart: (pos) {
                    widget.onReact?.call(pos.globalPosition);
                  },
                  onSecondaryTapDown: (pos) {
                    if (event.messageType == MessageTypes.Text) {
                      // only enable fast reply and reaction on text data
                      widget.onReact?.call(pos.globalPosition);
                    }
                  },
                  onLongPressUp: () {},
                  child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: min<double>(
                            MediaQuery.of(context).size.width * 0.7, 500),
                      ),
                      child: Buble(
                          e: event,
                          state: widget,
                          replyEvent: snapReplyEvent.data)),
                ),
                if (keys.entries.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Transform.translate(
                      offset: const Offset(0, -4),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (MapEntry<String?, int> key in keys.entries)
                              Material(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                child: Padding(
                                  padding: const EdgeInsets.all(1.6),
                                  child: Material(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 4),
                                      child: GestureDetector(
                                          onLongPress: () =>
                                              displayReactionDialog(context),
                                          child: MaterialButton(
                                              minWidth: 8,
                                              height: 0,
                                              padding: const EdgeInsets.only(),
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              onPressed: () =>
                                                  displayReactionDialog(
                                                      context),
                                              child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(key.key!,
                                                        style: const TextStyle(
                                                            fontSize: 12)),
                                                    const SizedBox(width: 2),
                                                    Text(key.value.toString(),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall)
                                                  ]))),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
