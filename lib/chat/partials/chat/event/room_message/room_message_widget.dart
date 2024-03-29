import 'dart:math';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/chat/minestrix_chat.dart';
import 'package:piaf/chat/partials/chat/event/room_message/event_reactions.dart';
import 'package:piaf/chat/utils/l10n/event_localisation_extension.dart';

import '../../../dialogs/adaptative_dialogs.dart';
import '../../../matrix/matrix_image_avatar.dart';
import 'event_reactions_dialog.dart';
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
      builder: (context) => EventReactionsDialog(reactions: widget.reactions!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sentByUser = event.sentByUser;

    Map<String?, int> keys = getFilteredReactionsList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!sentByUser)
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
              crossAxisAlignment: sentByUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!sentByUser && widget.displayName || snapReplyEvent.hasData)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Wrap(
                      children: [
                        snapReplyEvent.hasData
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.reply,
                                      size: 18,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                        "${event.senderLocalisedDisplayName} relpied to ${snapReplyEvent.data!.senderLocalisedDisplayName}",
                                        maxLines: 2,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              )
                            : Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                    event.senderFromMemoryOrFallback
                                        .calcDisplayname(),
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              ),
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
                        child: EventReactions(
                            displayReactionDialog: displayReactionDialog,
                            keys: keys)),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Map<String?, int> getFilteredReactionsList() {
    var keys = <String?, int>{};
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
    return keys;
  }
}
