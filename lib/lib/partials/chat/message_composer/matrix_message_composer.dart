import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/pages/device_media_gallery.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/client_information.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../style/constants.dart';
import '../../../utils/platform_infos.dart';

class MatrixMessageComposer extends StatefulWidget {
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

  const MatrixMessageComposer(
      {Key? key,
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
      this.loadSavedText = true})
      : super(key: key);

  @override
  MatrixMessageComposerState createState() => MatrixMessageComposerState();
}

class MatrixMessageComposerState extends State<MatrixMessageComposer> {
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

    super.initState();
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
    if (PlatformInfos.isAndroid) {
      final result = await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const DeviceMediaGallery()));
      if (result is List<AssetEntity> && result.isNotEmpty) {
        final returnedFile = await result.first.file;
        final data = await returnedFile?.readAsBytes();
        if (data != null) {
          setState(() {
            file = PlatformFile(
                name: result.first.title ?? '', size: data.length, bytes: data);
          });
        }
      }
    } else {
      final f = (await FilePicker.platform
              .pickFiles(type: FileType.image, withData: true))
          ?.files
          .first;

      setState(() {
        file = f;
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
    editTimer = Timer(const Duration(milliseconds: 600), () {
      widget.client
          .setDraft(message: text, roomId: room?.id ?? widget.userId ?? '');
    });
  }

  void onEdit(String text) {
    setMessageDraft(text);

    widget.onEdit?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    double defaultHeight = 55;
    return LayoutBuilder(builder: (context, constraints) {
      return Column(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (constraints.maxWidth > 600)
                SizedBox(
                  height: defaultHeight,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: FutureBuilder(
                        future: widget.client.fetchOwnProfile(),
                        builder:
                            (BuildContext context, AsyncSnapshot<Profile> p) {
                          return MatrixImageAvatar(
                            client: widget.client,
                            url: p.data?.avatarUrl,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            defaultText:
                                p.data?.displayName ?? widget.client.userID,
                            fit: true,
                            height: MinestrixAvatarSizeConstants.small,
                            width: MinestrixAvatarSizeConstants.small,
                          );
                        }),
                  ),
                ),
              if (widget.allowSendingPictures &&
                  room != null &&
                  (!_isTyping || isAutoFocusEnabled))
                SizedBox(
                  height: defaultHeight,
                  child: IconButton(
                    onPressed: () {
                      if (room != null) addImage(context, room!);
                    },
                    tooltip: 'Send file',
                    icon: const Icon(Icons.attach_file),
                  ),
                ),
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
                            if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
                              _sendMessageOrCreate();
                              shouldResetView = true;
                            }

                            if (event.isKeyPressed(LogicalKeyboardKey.keyV)) {
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
                            decoration: !_isTyping || isAutoFocusEnabled
                                ? Constants.kTextFieldInputDecoration.copyWith(
                                    prefixIcon: const Icon(
                                      Icons.message,
                                    ),
                                    hintText: widget.hintText,
                                  )
                                : InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 12),
                                    border: InputBorder.none,
                                    enabledBorder: const OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(22),
                                      ),
                                    ),
                                    focusedBorder: const OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(22),
                                      ),
                                    ),
                                    filled: true,
                                    hintText: widget.hintText,
                                  )),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: defaultHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: _isSending
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Icon(Icons.send,
                              color: Theme.of(context).colorScheme.primary),
                      color: Colors.white,
                      onPressed:
                          _isSending == true ? null : _sendMessageOrCreate,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}
