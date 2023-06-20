import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/event/matrix_image.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/partials/poll/poll_widget.dart';
import 'package:minestrix_chat/utils/extensions/matrix/event_extension.dart';
import 'package:minestrix_chat/utils/l10n/event_localisation_extension.dart';
import 'package:minestrix_chat/utils/matrix_sdk_extension/matrix_file_extension.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../dialogs/adaptative_dialogs.dart';
import '../../../matrix/reactions_list.dart';
import '../../user/user_info_dialog.dart';
import 'call_message_dispaly.dart';
import 'matrix_video_message.dart';
import 'text_message_bubble.dart';

class MessageDisplay extends StatefulWidget {
  final Event event;
  final Timeline? timeline;

  final Set<Event>? reactions;

  final Client? client;

  final void Function()? onReply;
  final void Function(Event reply)? onReplyEventPressed;
  final void Function(Offset)? onReact;

  final bool displayAvatar;
  final bool displayName;
  final bool addPaddingTop;
  final bool edited;
  final bool isLastMessage;

  final Stream<String>? onEventSelectedStream;
  const MessageDisplay(
      {Key? key,
      required this.event,
      required this.client,
      this.reactions,
      this.onReact,
      this.timeline,
      this.onEventSelectedStream,
      this.onReply,
      this.isLastMessage = false,
      this.displayAvatar = false,
      this.displayName = false,
      this.addPaddingTop = false,
      this.edited = false,
      this.onReplyEventPressed})
      : super(key: key);

  @override
  MessageDisplayState createState() => MessageDisplayState();
}

class MessageDisplayState extends State<MessageDisplay>
    with TickerProviderStateMixin {
  late AnimationController _resizableController;
  StreamSubscription? onEventSelectedListener;
  @override
  void initState() {
    super.initState();

    _resizableController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 3000,
      ),
    );
    onEventSelectedListener = widget.onEventSelectedStream?.listen((event) {
      _resizableController.reset();
      _resizableController.forward();
    });
  }

  // when using is pressing down, we disable the drag
  Event? getUserReactionEvent(String key) {
    if (widget.reactions == null) return null;
    for (Event ev in widget.reactions!) {
      if (ev.senderId == widget.client!.userID) {
        if (key == ev.emoji) return ev;
      }
    }
    return null;
  }

  Future<void> dowloadAttachement() async {
    final file = await widget.event.downloadAndDecryptAttachment(
      downloadCallback: (Uri url) async {
        final file = await DefaultCacheManager().getSingleFile(url.toString());
        return await file.readAsBytes();
      },
    );
    if (mounted) {
      file.save(context);
    }
  }

  Widget buildMessageWidget(context, Event e) {
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
    bool redacted = e.type == EventTypes.Redaction;

    final foregroundColor = e.sentByUser
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    final backgroundColor = e.sentByUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).cardColor;

    final messageBackgroundColor = e.messageType == MessageTypes.Notice
        ? Theme.of(context).cardColor
        : backgroundColor;

    final messageForegroundColor = e.messageType == MessageTypes.Notice
        ? Theme.of(context).colorScheme.onSurface
        : foregroundColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!e.sentByUser)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2.0, right: 10),
            child: SizedBox(
              width: 40,
              child: widget.displayAvatar
                  ? MaterialButton(
                      onPressed: () async {
                        await UserInfoDialog.show(
                            user: e.sender, context: context);
                      },
                      minWidth: 0,
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                      child: MatrixImageAvatar(
                          url: e.sender.avatarUrl,
                          defaultText: e.sender.calcDisplayname(),
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
              e.relationshipType == RelationshipTypes.reply) {
            return e.getReplyEvent(widget.timeline!);
          }

          return null;
        }(), builder: (context, snapReplyEvent) {
          return Expanded(
            child: Column(
              crossAxisAlignment: e.sentByUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!e.sentByUser && widget.displayName ||
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
                                          "${e.senderLocalisedDisplayName} relpied to ${snapReplyEvent.data!.senderLocalisedDisplayName}",
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              )
                            : Text(e.sender.calcDisplayname(),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color)),
                        if (e.sentByUser == false && widget.displayName)
                          Text(" - ",
                              style: TextStyle(
                                  color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color ??
                                      Colors.grey)),
                        if (e.sentByUser == false && widget.displayName)
                          Text(timeago.format(e.originServerTs),
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color ??
                                      Colors.grey)),
                      ],
                    ),
                  ),
                GestureDetector(
                  onLongPressStart: (pos) {
                    widget.onReact?.call(pos.globalPosition);
                  },
                  onSecondaryTapDown: (pos) {
                    if (e.messageType == MessageTypes.Text) {
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
                    child: Builder(builder: (context) {
                      switch (e.messageType) {
                        case MessageTypes.Image:
                        case MessageTypes.Sticker:
                          return ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: min<double>(
                                    MediaQuery.of(context).size.width * 0.6,
                                    300),
                                maxHeight: min<double>(
                                    MediaQuery.of(context).size.height * 0.4,
                                    400),
                              ),
                              child: MImageViewer(event: e));
                        case MessageTypes.Video:
                          return ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: min<double>(
                                    MediaQuery.of(context).size.width * 0.6,
                                    300),
                                maxHeight: min<double>(
                                    MediaQuery.of(context).size.height * 0.4,
                                    400),
                              ),
                              child: MatrixVideoMessage(e,
                                  key: Key("video_${e.eventId}")));

                        case MessageTypes.Audio:
                          return Card(
                              color: backgroundColor,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListTile(
                                    onTap: dowloadAttachement,
                                    leading: Icon(Icons.audio_file,
                                        color: foregroundColor),
                                    title: Text("Audio",
                                        style:
                                            TextStyle(color: foregroundColor)),
                                    subtitle: Text(e.body,
                                        style:
                                            TextStyle(color: foregroundColor))),
                              ));
                        case MessageTypes.File:
                          return Card(
                              color: backgroundColor,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListTile(
                                    onTap: dowloadAttachement,
                                    leading: Icon(Icons.file_present,
                                        color: foregroundColor),
                                    title: Text("File",
                                        style:
                                            TextStyle(color: foregroundColor)),
                                    subtitle: Text(e.body,
                                        style:
                                            TextStyle(color: foregroundColor))),
                              ));
                        default:
                          return Column(
                            crossAxisAlignment: e.sentByUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (e.relationshipType == RelationshipTypes.reply)
                                Transform.translate(
                                  offset: const Offset(0, 4.0),
                                  child: Builder(builder: (context) {
                                    if (!snapReplyEvent.hasData) {
                                      return Container();
                                    }
                                    final replyEvent = snapReplyEvent.data!;

                                    return InkWell(
                                      onTap: () => widget.onReplyEventPressed
                                          ?.call(replyEvent),
                                      child: Column(
                                        crossAxisAlignment: e.sentByUser
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        children: [
                                          Opacity(
                                            opacity: 0.6,
                                            child: TextMessageBubble(
                                                redacted: redacted,
                                                e: replyEvent,
                                                alignRight: e.sentByUser,
                                                isReply: true,
                                                color: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.color ??
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .onSurface,
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .cardColor),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              AnimatedBuilder(
                                  animation: _resizableController,
                                  builder: (BuildContext context,
                                          Widget? child) =>
                                      TextMessageBubble(
                                        redacted: redacted,
                                        e: e,
                                        displaySentIndicator:
                                            widget.isLastMessage &&
                                                e.sentByUser,
                                        edited: widget.edited,
                                        color: messageForegroundColor,
                                        backgroundColor: messageBackgroundColor,
                                        borderPadding: const EdgeInsets.all(3),
                                        borderColor: () {
                                          var pos = _resizableController.value;
                                          if (pos == 0 || pos == 1) {
                                            return messageBackgroundColor;
                                          }

                                          const duration = 0.15;
                                          const end = 1 - duration;

                                          if (pos < duration) {
                                            pos = pos / duration;
                                          } else if (pos > end) {
                                            pos = 1 - (pos - end) / duration;
                                          } else {
                                            pos = 1;
                                          }
                                          return Color.lerp(
                                              messageBackgroundColor,
                                              Colors.blue.shade800,
                                              pos);
                                        }(),
                                      )),
                            ],
                          );
                      }
                    }),
                  ),
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
                                        child: MaterialButton(
                                            minWidth: 8,
                                            height: 0,
                                            padding: const EdgeInsets.only(),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(key.key!,
                                                      style: const TextStyle(
                                                          fontSize: 12)),
                                                  const SizedBox(width: 2),
                                                  Text(key.value.toString(),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall)
                                                ]),
                                            onPressed: () async {
                                              final userEvent =
                                                  getUserReactionEvent(
                                                      key.key!);

                                              if (userEvent == null) {
                                                // prevent the user from sending the reaction twice. (Won't be accepted by the server)
                                                await e.room.sendReaction(
                                                    e.eventId, key.key!);
                                              } else {
                                                await userEvent.redactEvent();
                                              }
                                            }),
                                        onLongPress: () async {
                                          if (widget.reactions == null) return;
                                          await AdaptativeDialogs.show(
                                            context: context,
                                            title: "Reactions",
                                            builder: (context) =>
                                                EventReactionList(
                                                    reactions:
                                                        widget.reactions!),
                                          );
                                        },
                                      ),
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

  Widget buildRoomMessage({String? emoji, required String text}) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              //mainAxisSize: MainAxisSize.min,
              children: [
                if (emoji != null) Text(emoji),
                if (emoji != null) const SizedBox(width: 10),
                Text(text),
              ],
            ),
          ),
        ),
      );

  Widget buildPage(BuildContext context, Event event) {
    switch (event.type) {
      case EventTypes.Message:
      case EventTypes.Sticker:
      case EventTypes.Encrypted:
      case EventTypes.Redaction:
        switch (event.messageType) {
          case MessageTypes.Text:
          case MessageTypes.Emote:
          case MessageTypes.Image:
          case MessageTypes.Sticker:
          case MessageTypes.Notice:
          case MessageTypes.File:
          case MessageTypes.Audio:
          case MessageTypes.Video:
          case MessageTypes.BadEncrypted:
            return SwipeTo(
                onRightSwipe: widget.onReply,
                child: buildMessageWidget(context, event));

          default:
            return Text("other message type : ${event.messageType}");
        }
      case EventTypes.RoomMember:
      case EventTypes.RoomName:
      case EventTypes.RoomJoinRules:
      case EventTypes.RoomTopic:
      case EventTypes.RoomAvatar:
      case EventTypes.HistoryVisibility:
      case EventTypes.RoomPowerLevels:
      case EventTypes.RoomCanonicalAlias:
      case EventTypes.GuestAccess:
        return Text(event.getLocalizedBody(const MatrixDefaultLocalizations()));
      case EventTypes.RoomCreate:
        return buildRoomMessage(
            emoji: "🎉",
            text: event.getLocalizedBody(const MatrixDefaultLocalizations()));

      case EventTypes.Encryption:
        return Card(
            child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.enhanced_encryption),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("End-To-End encryption activated"),
                      Text(
                          event.content.tryGet<String>("algorithm") ??
                              "An error happened - no algorithm given",
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
      case MatrixEventTypes.pollStart:
        if (event.redacted) {
          return buildRoomMessage(
              emoji: "🤔",
              text:
                  "${event.sender.displayName ?? event.sender.senderId} redacted a poll");
        }
        if (widget.timeline != null) {
          return PollWidget(event: event, timeline: widget.timeline!);
        }
        break;
      case MatrixEventTypes.pollResponse:
        return buildRoomMessage(
            emoji: "🎉",
            text:
                "${event.sender.displayName ?? event.sender.senderId} responded to a poll");
      case EventTypes.CallInvite:
        if (widget.timeline != null) {
          return CallMessageDisplay(event, timeline: widget.timeline!);
        }
        break;
      default:
    }
    // unknown event
    return buildRoomMessage(
        emoji: "🤔",
        text: event.getLocalizedBody(const MatrixDefaultLocalizations()));
  }

  bool hover = false;

  @override
  Widget build(BuildContext context) {
    if (widget.event.messageType == MessageTypes.BadEncrypted) {
      return FutureBuilder<Event>(
          future: widget.event.room.client.encryption!.decryptRoomEvent(
              widget.event.roomId!, widget.event,
              store: true),
          builder: (BuildContext context, snapshot) {
            if (snapshot.hasError) {
              return const Row(
                children: [
                  Icon(Icons.error),
                  SizedBox(
                    width: 10,
                  ),
                  Text("Could not load encrypted message"),
                ],
              );
            }
            return buildMouseRegion(context, snapshot.data ?? widget.event);
          });
    }

    // then load the event
    return buildMouseRegion(context, widget.event);
  }

  MouseRegion buildMouseRegion(BuildContext context, Event event) {
    return MouseRegion(
      child: Padding(
        padding: EdgeInsets.only(top: widget.addPaddingTop ? 16 : 3, right: 8),
        child: buildPage(context, event),
      ),
      onEnter: (_) => setState(() {
        hover = true;
      }),
      onExit: (_) => setState(() {
        hover = false;
      }),
    );
  }
}
