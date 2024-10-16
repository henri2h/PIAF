import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matrix/matrix.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:piaf/partials/matrix/matrix_image_avatar.dart';
import 'package:piaf/utils/client_information.dart';

import '../../../../utils/files_picker.dart';
import '../../../../utils/platform_infos.dart';

class MessageComposer extends StatefulWidget {
  final Client client;
  final Room? room;
  final String? userId;
  final Event? onReplyTo;
  final VoidCallback? onSend;
  final String hintText;

  final bool allowSendingPictures;
  final bool enableAutoFocusOnDesktop;

  /// set to true if we define a custom logic to send a message
  final Future<void> Function(String text)? overrideSending;
  final void Function(String text)? onEdit;
  final void Function(Room)? onRoomCreate;

  /// Save message draft
  final bool loadSavedText;

  const MessageComposer(
      {super.key,
      required this.client,
      this.userId,
      required this.room,
      this.hintText = "Send a message",
      this.allowSendingPictures = true,
      this.enableAutoFocusOnDesktop = true,
      this.onReplyTo,
      this.onSend,
      this.overrideSending,
      this.onRoomCreate,
      this.onEdit,
      this.loadSavedText = true});

  @override
  MessageComposerState createState() => MessageComposerState();
}

class MessageComposerState extends State<MessageComposer> {
  final TextEditingController _sendController = TextEditingController();

  Room? room;

  PlatformFile? file;
  Uint8List? fileBytes;
  bool _isSending = false;
  bool _isTyping = false;
  var focusNode = FocusNode();
  var textFieldFocusNode = FocusNode();
  bool shouldResetView =
      false; // should we clear the text input on the next key press

  bool get isAutoFocusEnabled =>
      PlatformInfos.isMobile ? false : widget.enableAutoFocusOnDesktop;

  Future<String?>? initialText;

  @override
  void initState() {
    room = widget.room;
    focusNode.addListener(onFocusChanged);
    initialText = loadText();

    if (isAutoFocusEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        textFieldFocusNode.requestFocus();
      });
    }

    _sendController.addListener(onTextChanged);

    super.initState();
  }

  // Refresh the widget when the user has written his first text
  bool _wasTextEmpty = false;
  void onTextChanged() {
    if (_sendController.text.isEmpty != _wasTextEmpty) {
      setState(() {
        _wasTextEmpty = _sendController.text.isEmpty;
      });
    }
  }

  Future<String?> loadText() async {
    if (!widget.loadSavedText) return null;
    final text = await widget.client.getDraft(room?.id ?? widget.userId ?? '');
    if (text != null) {
      setState(() {
        _sendController.text = text;
      });
    }
    return text;
  }

  void onFocusChanged() {
    if (focusNode.hasFocus) {
      _isTyping = true;
    } else {
      _isTyping = false;
    }
    setState(() {});
  }

  void addImage(BuildContext context, Room room) async {
    final result = await FilesPicker.pick(context);
    if (result?.isNotEmpty == true) {
      setState(() {
        file = result?.first;
      });
    }
  }

  Future<void> sendImage() async {
    if (file?.bytes != null) {
      await room?.sendFileEvent(
          MatrixImageFile(bytes: file!.bytes!, name: file!.name));
    }
  }

  Future<void> _sendMessage() async {
    final text = _sendController.text;
    final onReplyTo = widget.onReplyTo;
    // clear state
    setState(() {
      _isSending = true;
      _sendController.clear();
      _isTyping = false;
    });

    if (text != "") {
      widget.onSend?.call();

      if (widget.overrideSending == null) {
        room?.sendTextEvent(text, inReplyTo: onReplyTo);
      } else {
        await widget.overrideSending!(text);
      }
    }

    if (file?.bytes != null) {
      sendImage();
      file = null;
    }

    setState(() {
      _isSending = false;
    });

    setMessageDraft("");
  }

  Future<void> _sendMessageOrCreate() async {
    if (room != null) return await _sendMessage();

    if (widget.userId?.isValidMatrixId == true &&
        widget.userId?.startsWith("@") == true) {
      final roomId = await widget.client.startDirectChat(widget.userId!);
      room = widget.client.getRoomById(roomId);
      if (room != null) {
        await _sendMessage();

        widget.onRoomCreate?.call(room!);

        if (mounted) {
          setState(() {});
        }

        // remove message text from drafts. (As we change the roomId, the automatic cleaninup doesn't work)
        widget.client.setDraft(message: '', roomId: widget.userId ?? '');
      }
    }
  }

  Timer? editTimer;

  void setMessageDraft(String text) {
    editTimer?.cancel();
    editTimer = Timer(const Duration(milliseconds: 600), () async {
      await widget.client
          .setDraft(message: text, roomId: room?.id ?? widget.userId ?? '');
    });
  }

  void onEdit(String text) {
    setMessageDraft(text);

    widget.onEdit?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    double defaultHeight = 48;
    return LayoutBuilder(builder: (context, constraints) {
      return Padding(
        padding: const EdgeInsets.only(top: 4.0, bottom: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (file?.bytes != null)
              Stack(
                children: [
                  ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: Image.memory(file!.bytes!)),
                  Positioned(
                    right: 15,
                    top: 10,
                    child: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            file = null;
                          });
                        }),
                  ),
                ],
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (constraints.maxWidth > 600)
                  UserAvatar(defaultHeight: defaultHeight, widget: widget),
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: defaultHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Center(
                        child: RawKeyboardListener(
                            focusNode: focusNode,
                            onKey: (event) async {
                              if (shouldResetView) {
                                setState(() {
                                  _sendController.clear();
                                  shouldResetView = false;
                                  setMessageDraft("");
                                });
                              }

                              if (event.isControlPressed) {
                                if (event
                                    .isKeyPressed(LogicalKeyboardKey.enter)) {
                                  _sendMessageOrCreate();
                                  shouldResetView = true;
                                }

                                if (event
                                    .isKeyPressed(LogicalKeyboardKey.keyV)) {
                                  final imageBytes = await Pasteboard.image;
                                  if (imageBytes != null) {
                                    setState(() {
                                      file = PlatformFile(
                                          name: "clipboard",
                                          size: imageBytes.length,
                                          bytes: imageBytes);
                                    });
                                  }
                                }
                              }
                            },
                            child: TextField(
                                autofocus: isAutoFocusEnabled,
                                focusNode: textFieldFocusNode,
                                maxLines: 5,
                                minLines: 1,
                                controller: _sendController,
                                onChanged: onEdit,
                                keyboardType: TextInputType.multiline,
                                textAlignVertical: TextAlignVertical.center,
                                decoration: InputDecoration(
                                    filled: true,
                                    border: InputBorder.none,
                                    prefixIcon: _isTyping
                                        ? null
                                        : const Icon(
                                            Icons.message,
                                          ),
                                    enabledBorder: const OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(16),
                                      ),
                                    ),
                                    focusedBorder: const OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(16),
                                      ),
                                    ),
                                    hintText: widget.hintText,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 12),
                                    suffixIcon: widget.allowSendingPictures &&
                                            room != null &&
                                            (!_isTyping || isAutoFocusEnabled)
                                        ? IconButton(
                                            onPressed: () {
                                              if (room != null) {
                                                addImage(context, room!);
                                              }
                                            },
                                            icon: Icon(Icons.image))
                                        : null))),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, right: 4),
                  child: SizedBox(
                    height: defaultHeight,
                    width: 40,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _isSending
                            ? const CircularProgressIndicator()
                            : IconButton.filled(
                                icon: Icon(
                                  Icons.send,
                                ),
                                onPressed: !_isSending &&
                                        (_sendController.text.isNotEmpty ||
                                            file != null)
                                    ? _sendMessageOrCreate
                                    : null,
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.defaultHeight,
    required this.widget,
  });

  final double defaultHeight;
  final MessageComposer widget;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: defaultHeight,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: FutureBuilder(
            future: widget.client.fetchOwnProfile(),
            builder: (BuildContext context, AsyncSnapshot<Profile> p) {
              return MatrixImageAvatar(
                client: widget.client,
                url: p.data?.avatarUrl,
                backgroundColor: Theme.of(context).colorScheme.primary,
                defaultText: p.data?.displayName ?? widget.client.userID,
                fit: true,
                height: MinestrixAvatarSizeConstants.small,
                width: MinestrixAvatarSizeConstants.small,
              );
            }),
      ),
    );
  }
}
