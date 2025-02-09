import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matrix/matrix.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:piaf/partials/matrix/matrix_image_avatar.dart';
import 'package:piaf/utils/client_information.dart';

import '../../../../config/app_config.dart';
import '../../../../utils/files_picker.dart';
import '../../../../utils/matrix_widget.dart';
import '../../../../utils/platform_infos.dart';

class MessageComposerController {
  final TextEditingController text = TextEditingController();
}

class MessageComposer extends StatefulWidget {
  final Room? room;
  final String? userId;
  final Event? inReplyTo;
  final Event? editEvent;
  final VoidCallback? onSend;
  final String hintText;
  // Allows showing a progress indicator when sending a message. This will prevent sending other messages when the previous message hasn't been sent.
  final bool isSendingEnabled;

  final bool allowSendingPictures;
  final bool enableAutoFocusOnDesktop;

  final Stream<String>? inputStream;
  final TextEditingController? controller;

  /// set to true if we define a custom logic to send a message
  final Future<void> Function(String text)? overrideSending;
  final void Function(String text)? onEdit;
  final void Function(Room)? onRoomCreated;

  /// Save message draft
  final bool loadSavedText;

  const MessageComposer(
      {super.key,
      this.userId,
      required this.room,
      this.hintText = "Send a message",
      this.allowSendingPictures = true,
      this.enableAutoFocusOnDesktop = true,
      this.inReplyTo,
      this.onSend,
      this.overrideSending,
      this.onRoomCreated,
      this.onEdit,
      this.editEvent,
      this.loadSavedText = true,
      this.inputStream,
      this.controller,
      this.isSendingEnabled = false});

  @override
  MessageComposerState createState() => MessageComposerState();
}

class MessageComposerState extends State<MessageComposer> {
  late TextEditingController _sendController;

  Room? room;

  PlatformFile? file;
  Uint8List? fileBytes;
  bool _isSending = false;
  bool get isSending => widget.isSendingEnabled && _isSending;
  bool _isTyping = false;
  late FocusNode textFieldFocusNode;

  Future<void> pasteImage() async {
    final imageBytes = await Pasteboard.image;
    if (imageBytes != null) {
      setState(() {
        file = PlatformFile(
            name: "clipboard", size: imageBytes.length, bytes: imageBytes);
      });
    }
  }

  KeyEventResult keyHandler(node, event) {
    // Only listen when key is released. That's when the TextController is updated
    // Send message on ctrl + enter if controlEnterToSend == true or on enter
    if ((HardwareKeyboard.instance.isControlPressed ^
            !AppConfig.controlEnterToSend) &&
        event.logicalKey == LogicalKeyboardKey.enter) {
      if (event is KeyUpEvent) {
        _sendMessageOrCreate();
      }
      return KeyEventResult.handled;
    }

    // Paste image
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyV) {
      if (event is KeyUpEvent) {
        pasteImage();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  bool shouldResetView =
      false; // should we clear the text input on the next key press

  bool get isAutoFocusEnabled =>
      PlatformInfos.isMobile ? false : widget.enableAutoFocusOnDesktop;

  Future<String?>? initialText;
  StreamSubscription<String>? _streamSubscription;

  @override
  void initState() {
    _sendController = widget.controller ?? TextEditingController();
    room = widget.room;

    textFieldFocusNode = FocusNode(onKeyEvent: keyHandler);

    textFieldFocusNode.addListener(onFocusChanged);
    initialText = loadText();

    if (isAutoFocusEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        textFieldFocusNode.requestFocus();
      });
    }

    _sendController.addListener(onTextChanged);
    _streamSubscription = widget.inputStream?.listen((String text) {
      if (mounted) {
        // In case it's a command
        if (text.startsWith("/")) {
          _sendController.text = text;
        } else if (text.startsWith("@")) {
          // In this case it's a username

          // Replace the last mxid with the selected one
          _sendController.text = _sendController.text
                  .replaceAllMapped(RegExp(r'[@]\w*$'), (match) {
                return "";
              }) +
              text;
        }
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _sendController.removeListener(onTextChanged);
    _streamSubscription?.cancel();
    super.dispose();
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
    final client = Matrix.of(context).client;

    if (!widget.loadSavedText) return null;
    final text = await client.getDraft(room?.id ?? widget.userId ?? '');
    if (text != null) {
      setState(() {
        _sendController.text = text;
      });
    }
    return text;
  }

  void onFocusChanged() {
    if (textFieldFocusNode.hasFocus) {
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

  Future<void> _sendEventAndImage() async {
    final text = _sendController.text;
    final onReplyTo = widget.inReplyTo;
    // clear state
    setState(() {
      _isSending = true;
      _sendController.text = "";
      _isTyping = false;
    });

    await setMessageDraftImmediate("");
    // Test if the input is supposed to be a command
    if (!text.replaceAll(" ", "").startsWith("/")) {
      // Don't send if it's a command
      if (text != "") {
        widget.onSend?.call();
        if (widget.overrideSending == null) {
          await room?.sendTextEvent(text,
              inReplyTo: onReplyTo, editEventId: widget.editEvent?.eventId);
        } else {
          await widget.overrideSending!(text);
        }
      }

      if (file?.bytes != null) {
        sendImage();
        file = null;
      }
    } else {
      // In case it's a command
      await room?.client
          .parseAndRunCommand(room!, text, inReplyTo: widget.inReplyTo);
    }

    setState(() {
      _isSending = false;
    });
  }

  Future<void> _sendMessageOrCreate() async {
    final client = Matrix.of(context).client;

    if (room != null) return await _sendEventAndImage();

    if (widget.userId?.isValidMatrixId == true &&
        widget.userId?.startsWith("@") == true) {
      final roomId =
          await client.startDirectChat(widget.userId!, waitForSync: true);
      room = client.getRoomById(roomId);
      if (room != null) {
        await _sendEventAndImage();
        widget.onRoomCreated?.call(room!);

        if (mounted) {
          setState(() {});
        }

        // remove message text from drafts. (As we change the roomId, the automatic cleaninup doesn't work)
        client.setDraft(message: '', roomId: widget.userId ?? '');
      }
    }
  }

  Timer? editTimer;

  Future<void> _setMessageDraft(String text) async {
    final client = Matrix.of(context).client;
    await client.setDraft(
        message: text, roomId: room?.id ?? widget.userId ?? '');
  }

  Future<void> setMessageDraftImmediate(String text) async {
    editTimer?.cancel();
    await _setMessageDraft(text);
  }

  void setMessageDraftTimer(String text) {
    editTimer?.cancel();
    editTimer = Timer(const Duration(milliseconds: 600), () async {
      await _setMessageDraft(text);
    });
  }

  void onEdit(String text) {
    setMessageDraftTimer(text);

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
                  UserAvatar(defaultHeight: defaultHeight),
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: defaultHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Center(
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
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, right: 4),
                  child: SizedBox(
                    height: defaultHeight,
                    width: 40,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        isSending
                            ? const CircularProgressIndicator()
                            : IconButton.filled(
                                icon: Icon(
                                  Icons.send,
                                ),
                                onPressed: !isSending &&
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
  });

  final double defaultHeight;

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;

    return SizedBox(
      height: defaultHeight,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: FutureBuilder(
            future: client.fetchOwnProfile(),
            builder: (BuildContext context, AsyncSnapshot<Profile> p) {
              return MatrixImageAvatar(
                client: client,
                url: p.data?.avatarUrl,
                backgroundColor: Theme.of(context).colorScheme.primary,
                defaultText: p.data?.displayName ?? client.userID,
                fit: true,
                height: MinestrixAvatarSizeConstants.small,
                width: MinestrixAvatarSizeConstants.small,
              );
            }),
      ),
    );
  }
}
