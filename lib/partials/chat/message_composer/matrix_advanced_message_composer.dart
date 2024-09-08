import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/chat/message_composer/matrix_message_composer.dart';

/// Allow the user to send a message in a room. If a userId is given, it will
/// create a direct chat.
class MatrixAdvancedMessageComposer extends StatefulWidget {
  final Room? room;
  final String? userId;
  final Client client;
  final Event? reply;
  final VoidCallback removeReply;
  final void Function(Room)? onRoomCreate;
  final bool isMobile;

  const MatrixAdvancedMessageComposer({
    super.key,
    required this.room,
    required this.client,
    required this.reply,
    required this.removeReply,
    required this.isMobile,
    this.userId,
    required this.onRoomCreate,
  });

  @override
  MatrixAdvancedMessageComposerState createState() =>
      MatrixAdvancedMessageComposerState();
}

class MatrixAdvancedMessageComposerState
    extends State<MatrixAdvancedMessageComposer> {
  bool joiningRoom = false;
  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    Event? reply = widget.reply;

    final matrixComposerWidget = MatrixMessageComposer(
        client: widget.client,
        room: room,
        userId: widget.userId,
        onRoomCreate: widget.onRoomCreate,
        onReplyTo: reply,
        onSend: () {
          widget.removeReply();
          setState(() {});
        });

    return Column(
      children: [
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
                          widget.removeReply();
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
                : Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: matrixComposerWidget);
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
