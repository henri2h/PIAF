import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/features/chat/widgets/message_composer/message_composer.dart';
import 'package:piaf/partials/matrix/matrix_user_avatar.dart';
import 'package:piaf/utils/managers/string_distance.dart';
import 'package:piaf/utils/text.dart';

import '../../../../utils/matrix_widget.dart';

/// Allow the user to send a message in a room. If a userId is given, it will
/// create a direct chat.
class AdvancedMessageComposer extends StatefulWidget {
  final Room? room;
  final String? userId;
  final Event? replyEvent;
  // The original event that we want to edit
  final Event? editEvent;
  // The last modification of the event which we want to edit. This is used to get the latest edit text
  final Event? editDisplayEvent;

  final VoidCallback cancelEditAndReply;
  final void Function(Room)? onRoomCreated;
  final bool isMobile;

  const AdvancedMessageComposer({
    super.key,
    required this.room,
    required this.replyEvent,
    required this.editEvent,
    required this.editDisplayEvent,
    required this.cancelEditAndReply,
    required this.isMobile,
    this.userId,
    required this.onRoomCreated,
  });

  @override
  AdvancedMessageComposerState createState() => AdvancedMessageComposerState();
}

class AdvancedMessageComposerState extends State<AdvancedMessageComposer> {
  bool joiningRoom = false;

  final inputStream = StreamController<String>();
  final controller = TextEditingController();
  bool suggestionChosed = false;
  @override
  void initState() {
    controller.addListener(onEdit);
    super.initState();
  }

  @override
  void dispose() {
    controller.removeListener(onEdit);
    super.dispose();
  }

  void onEdit() {
    //if (controller.text == "/")
    setState(() {});
    suggestionChosed = false;
  }

  List<String> get commands {
    // If the user has pressed space, the we shouldn't display the suggestions.
    if (!controller.text.startsWith("/") ||
        controller.text.contains(" ") ||
        suggestionChosed) {
      return [];
    }

    final client = Matrix.of(context).client;

    final list = client.commands.keys.toList();
    final text = controller.text.replaceFirst("/", "");

    final map = <String, int>{};

    int i = 0;
    while (i < list.length) {
      final command = list[i];

      // Compare only the beggining of the text
      final aName = command.substring(0, min(command.length, text.length));

      final dist = levenstheinDistance(aName, text);

      if (dist < 2) {
        map[command] = dist;
        i++;
      } else {
        list.removeAt(i);
      }
    }

    list.sort((A, B) {
      int aDist = map[A]!;
      int bDist = map[B]!;

      return aDist.compareTo(bDist);
    });

    return list;
  }

  /// WARNING: The list might not be complete
  List<User> get usersList {
    final name = controller.text.split("@").last.toLowerCase();

    // Return the filtered participants list
    return widget.room
            ?.getParticipants()
            .where((u) =>
                u.id.startsWith("@$name") ||
                u.displayName
                        ?.toLowerCase()
                        .removeDiacritics()
                        .contains(name.removeDiacritics()) ==
                    true)
            .toList() ??
        [];
  }

  bool get writingUsername => controller.text.contains("@");

  Event? _cachedEditEvent;
  @override
  Widget build(BuildContext context) {
    // See if a new edit event has been set. If yes, then use it to populate the messeage composer field
    if (_cachedEditEvent != widget.editEvent) {
      _cachedEditEvent = widget.editEvent;
      if (widget.editEvent != null) {
        controller.text = (widget.editDisplayEvent ?? widget.editEvent)!
            .calcUnlocalizedBody(hideEdit: true, hideReply: true);
      }
    }

    final room = widget.room;
    Event? reply = widget.replyEvent;
    final client = Matrix.of(context).client;

    final matrixComposerWidget = MessageComposer(
        room: room,
        userId: widget.userId,
        onRoomCreated: widget.onRoomCreated,
        inReplyTo: reply,
        editEvent: widget.editEvent,
        inputStream: inputStream.stream,
        controller: controller,
        onSend: () {
          widget.cancelEditAndReply();
          setState(() {});
        });

    return Column(
      children: [
        if (controller.text.startsWith("/") || writingUsername)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 200),
            child: ListView(shrinkWrap: true, children: [
              for (final command in commands)
                ListTile(
                  leading: Icon(Icons.bolt),
                  title: Text("/$command"),
                  onTap: () {
                    inputStream.add("/$command");
                    setState(() {
                      suggestionChosed = true;
                    });
                  },
                ),
              for (final user in usersList)
                ListTile(
                  leading: MatrixUserAvatar.fromUser(user, client: client),
                  title: Text(user.calcDisplayname()),
                  subtitle: Text(user.id,
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                  onTap: () {
                    inputStream.add(user.id);
                    setState(() {
                      suggestionChosed = true;
                    });
                  },
                )
            ]),
          ),
        if (room?.membership == Membership.invite)
          MaterialButton(
              color: Colors.green,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (joiningRoom)
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    const Text("Join room",
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              onPressed: () async {
                if (joiningRoom == false) {
                  setState(() {
                    joiningRoom = true;
                  });
                  await room?.join();
                  setState(() {
                    joiningRoom = false;
                  });
                }
              }),
        if (_cachedEditEvent != null)
          Card(
            child: Row(
              children: [
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text("Edit message"),
                )),
                IconButton(
                    onPressed: () {
                      widget.cancelEditAndReply();
                    },
                    icon: Icon(Icons.close))
              ],
            ),
          ),
        if (reply != null)
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 0, left: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                    "Replying to ${reply.senderFromMemoryOrFallback.calcDisplayname()}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ),
                            ],
                          ),
                          const Divider(),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 140),
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: MarkdownBody(data: reply.body),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.cancel),
                        onPressed: () {
                          widget.cancelEditAndReply();
                          setState(() {});
                        })
                  ],
                ),
              ),
            ),
          ),
        if ((room?.canSendDefaultMessages == true ||
                (widget.userId?.isValidMatrixId == true &&
                    widget.userId?.startsWith("@") == true)) &&
            (room == null ||
                (room.membership.isJoin == true &&
                    (!room.encrypted || room.client.encryptionEnabled))))
          Builder(builder: (context) {
            return widget.isMobile && Platform.isIOS
                ? Container(
                    color: Theme.of(context)
                        .scaffoldBackgroundColor
                        .withAlpha(200),
                    child: ClipRect(
                        child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: matrixComposerWidget)))
                : matrixComposerWidget;
          }),
        if (room?.canSendDefaultMessages == false ||
            room != null && room.membership.isJoin != true)
          Container(
              color: Theme.of(context).cardColor,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.privacy_tip),
                    SizedBox(
                      width: 14,
                    ),
                    Expanded(
                        child: Text(
                            "You don't have the permission to write in this room")),
                  ],
                ),
              )),
        if (room != null && room.encrypted && !room.client.encryptionEnabled)
          Container(
              color: Theme.of(context).cardColor,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.privacy_tip),
                    SizedBox(
                      width: 14,
                    ),
                    Expanded(
                      child: Text(
                          "Encryption not supported. Cannot send messages in an encrypted room."),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}
