import 'dart:math';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/chat/minestrix_chat.dart';
import 'package:piaf/chat/partials/chat/event/room_message/event_reactions.dart';

import '../../../dialogs/adaptative_dialogs.dart';
import '../../../matrix/matrix_image_avatar.dart';
import '../../user/user_info_dialog.dart';
import '../event_widget.dart';
import 'bubles/buble.dart';
import 'event_reactions_dialog.dart';

class RoomMessageWidget extends StatelessWidget {
  const RoomMessageWidget({
    super.key,
    required this.eventWidgetState,
    required this.event,
  });

  final EventWidget eventWidgetState;
  final Event event;

  Future<void> displayReactionDialog(BuildContext context) async {
    if (eventWidgetState.reactions == null) return;
    await AdaptativeDialogs.show(
      context: context,
      title: "Reactions",
      builder: (context) =>
          EventReactionsDialog(reactions: eventWidgetState.reactions!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sentByUser = event.sentByUser;

    Map<String?, int> keys = getFilteredReactionsList();

    return FutureBuilder<User?>(
        future: event.room.requestUser(event.senderId),
        builder: (context, snapshot) {
          final user = snapshot.data ?? event.senderFromMemoryOrFallback;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!sentByUser)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 2.0, right: 10),
                  child: SizedBox(
                    width: 40,
                    child: eventWidgetState.displayAvatar
                        ? MaterialButton(
                            onPressed: () async {
                              await UserInfoDialog.show(
                                  user: user, context: context);
                            },
                            minWidth: 0,
                            padding: EdgeInsets.zero,
                            shape: const CircleBorder(),
                            child: MatrixImageAvatar(
                                url: user.avatarUrl,
                                defaultText: user.calcDisplayname(),
                                width: MinestrixAvatarSizeConstants.small,
                                height: MinestrixAvatarSizeConstants.small,
                                fit: true,
                                client: eventWidgetState.client),
                          )
                        : null,
                  ),
                ),
              FutureBuilder<Event?>(future: () async {
                if (eventWidgetState.timeline != null &&
                    event.relationshipType == RelationshipTypes.reply) {
                  return event.getReplyEvent(eventWidgetState.timeline!);
                }

                return null;
              }(), builder: (context, snapReplyEvent) {
                return Expanded(
                  child: Column(
                    crossAxisAlignment: sentByUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onLongPressStart: (pos) {
                          eventWidgetState.onReact?.call(pos.globalPosition);
                        },
                        onSecondaryTapDown: (pos) {
                          if (event.messageType == MessageTypes.Text) {
                            // only enable fast reply and reaction on text data
                            eventWidgetState.onReact?.call(pos.globalPosition);
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
                                eventWidgetState: eventWidgetState,
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
        });
  }

  Map<String?, int> getFilteredReactionsList() {
    var keys = <String?, int>{};
    if (eventWidgetState.reactions != null) {
      for (Event revent in eventWidgetState.reactions!) {
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
