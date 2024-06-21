import 'dart:math';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/minestrix_chat.dart';
import 'package:piaf/partials/chat/event/event_types/room_message/event_reactions.dart';

import '../../../dialogs/adaptative_dialogs.dart';
import '../../../matrix/matrix_image_avatar.dart';
import '../../user/user_info_dialog.dart';
import '../event_widget.dart';
import 'room_message/buble.dart';
import '../dialogs/event_reactions_dialog.dart';

class EventTypeRoomMessage extends StatelessWidget {
  const EventTypeRoomMessage({
    super.key,
    required this.state,
  });

  final EventWidget state;

  Future<void> displayReactionDialog(BuildContext context) async {
    if (state.ctx.reactions == null) return;
    await AdaptativeDialogs.show(
      context: context,
      title: "Reactions",
      builder: (context) =>
          EventReactionsDialog(reactions: state.ctx.reactions!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sentByUser = state.ctx.sentByUser;

    Map<String?, int> keys = getFilteredReactionsList();

    return FutureBuilder<User?>(
        future: state.ctx.event.room.requestUser(state.ctx.event.senderId),
        builder: (context, snapshot) {
          final user =
              snapshot.data ?? state.ctx.event.senderFromMemoryOrFallback;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!sentByUser)
                state.ctx.isDirectChat
                    ? const SizedBox(
                        width:
                            4) // Don't display user avatar in a direct chat but add a bit of padding
                    : Padding(
                        padding:
                            const EdgeInsets.only(left: 4, top: 2.0, right: 10),
                        child: SizedBox(
                          width: 40,
                          child: state.displayAvatar
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
                                      height:
                                          MinestrixAvatarSizeConstants.small,
                                      fit: true,
                                      client: state.ctx.client),
                                )
                              : null,
                        ),
                      ),
              FutureBuilder<Event?>(future: () async {
                if (state.ctx.timeline != null &&
                    state.ctx.event.relationshipType ==
                        RelationshipTypes.reply) {
                  return state.ctx.event.getReplyEvent(state.ctx.timeline!);
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
                          state.onReact?.call(pos.globalPosition);
                        },
                        onSecondaryTapDown: (pos) {
                          if (state.ctx.event.messageType ==
                              MessageTypes.Text) {
                            // only enable fast reply and reaction on text data
                            state.onReact?.call(pos.globalPosition);
                          }
                        },
                        onLongPressUp: () {},
                        child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: min<double>(
                                  MediaQuery.of(context).size.width * 0.7, 500),
                            ),
                            child: Buble(
                                state: state, replyEvent: snapReplyEvent.data)),
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
    if (state.ctx.reactions != null) {
      for (Event revent in state.ctx.reactions!) {
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
