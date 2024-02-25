import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/chat/minestrix_chat.dart';
import 'package:piaf/chat/partials/feed/minestrix_room_tile.dart';
import 'package:piaf/chat/utils/matrix_sdk_extension/matrix_file_extension.dart';
import 'package:piaf/chat/utils/matrix_sdk_extension/matrix_video_file_extension.dart';

import '../../../utils/extensions/minestrix/model/social_item.dart';
import '../../dialogs/adaptative_dialogs.dart';
import '../../matrix/matrix_image_avatar.dart';
import 'matrix_post_content.dart';
import 'matrix_post_image_list_editor.dart';

class PostEditorPage extends StatefulWidget {
  /// Allow creating or editing a post. In case of edition, don't forgot to set also the eventToEdit parameter
  /// so we know which event to edit and give the latest event to post so we can display the latests edits.
  const PostEditorPage(
      {super.key,
      this.room,
      this.post,
      this.eventToEditId,
      this.shareEvent,
      this.sendImage = false})
      : assert(room != null || post != null);
  final List<Room>? room;
  final Event? post;
  final String? eventToEditId;
  final bool sendImage;
  final Event? shareEvent;

  static Future<void> show({
    required BuildContext context,
    required List<Room> rooms,
    Event? shareEvent,
  }) async {
    if (rooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Theme.of(context).colorScheme.background,
          content: const ListTile(
            leading: Icon(Icons.error),
            title: Text("No room available to write a post."),
            subtitle: Text("First create a profile room."),
          )));
      return;
    }
    await AdaptativeDialogs.show(
        context: context,
        builder: (context) =>
            PostEditorPage(shareEvent: shareEvent, room: rooms));
  }

  static Future<void> showEditModalAndEdit({
    required BuildContext context,
    required Event event,
    Event? eventToEdit,
  }) async {
    await AdaptativeDialogs.show(
        context: context,
        builder: (context) =>
            PostEditorPage(post: event, eventToEditId: eventToEdit?.eventId));
  }

  @override
  PostEditorPageState createState() => PostEditorPageState();
}

class ImageListController {
  List<PlatformFile> imagesToAdd = [];

  Future<void> addPictures(BuildContext context) async {
    final files = await FilesPicker.pick(context);
    if (files != null) {
      imagesToAdd.addAll(files);
    }
  }
}

class PostEditorPageState extends State<PostEditorPage>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final imageController = ImageListController();
  final List<String> imagesRefEventId = [];
  double? uploadingStatus;

  bool _sending = false;
  bool get _isEdit => post != null;

  List<Room> get rooms => widget.room ?? [room];

  late Room room;
  Event? post;
  @override
  void initState() {
    super.initState();
    if (widget.room?.isNotEmpty == true) {
      room = widget.room!.first;
    }

    if (widget.post != null) {
      post = widget.post!;
      _textController.text = post?.postText ?? '';

      room = widget.post!.room;
      imagesRefEventId.addAll(widget.post!.imagesRefEventId);
    }
  }

  bool isTextNotEmpty = false;

  bool get canSend {
    return _sending == false && isTextNotEmpty;
  }

  Future<void> sendPost() async {
    setState(() {
      _sending = true;
    });

    // upload file content

    for (var fileToAdd in imageController.imagesToAdd) {
      if (fileToAdd.bytes == null) {
        continue;
      }

      var file = MatrixFile(bytes: fileToAdd.bytes!, name: fileToAdd.name)
          .detectFileType;
      MatrixImageFile? thumbnail;

      if (mounted && file is MatrixVideoFile && file.bytes.length > 20 * 1024) {
        // don't compress video of less than 1024 kb
        await showFutureLoadingDialog(
          context: context,
          future: () async {
            file = await file.resizeVideo();
            thumbnail = await file.getVideoThumbnail();
          },
        );
      }
      final imageEventId = await room.sendFileEvent(file, thumbnail: thumbnail);

      if (mounted) {
        setState(() {
          uploadingStatus =
              imagesRefEventId.length / imageController.imagesToAdd.length;
        });
      }

      // add image to the post image list
      if (imageEventId != null) {
        imagesRefEventId.add(imageEventId);
      }
    }

    // send the pictures
    if (_isEdit) {
      await post!.editPost(
        eventId: widget.eventToEditId,
        body: _textController.text,
        imagesRef: imagesRefEventId,
      );
    } else {
      await room.sendSocialPost(
          content: _textController.text,
          imagesRef: imagesRefEventId,
          shareEvent: widget.shareEvent);
    }

    setState(() {
      _sending = false;
    });

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void selectRoom(Room room) {
    setState(() {
      this.room = room;
    });
  }

  @override
  Widget build(BuildContext context) {
    Client client = room.client;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create post"),
        actions: [
          if (!_isEdit)
            MaterialButton(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                onPressed: () async {
                  await imageController.addPictures(context);
                  if (mounted) setState(() {});
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.add_a_photo),
                    ],
                  ),
                )),
          Card(
              color: !canSend ? Colors.grey : Colors.green,
              child: IconButton(
                  icon: _sending
                      ? Center(
                          child: CircularProgressIndicator(
                          color: Colors.white,
                          value: uploadingStatus,
                        ))
                      : Icon(_isEdit ? Icons.edit : Icons.send,
                          color: Colors.white),
                  onPressed: canSend ? sendPost : null))
        ],
      ),
      body: ListView(
        children: [
          Card(
            child: Column(
              children: [
                FutureBuilder<Profile>(
                    future: client.getProfileFromUserId(client.userID!),
                    builder: (context, snap) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            MatrixImageAvatar(
                                client: client,
                                url: snap.data?.avatarUrl,
                                defaultText: snap.data?.displayName,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary),
                            const SizedBox(
                              width: 14,
                            ),
                            Text("Post as ${snap.data?.displayName} on",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }),
                InkWell(
                  onTap: rooms.length == 1
                      ? null
                      : () async {
                          await showModalBottomSheet(
                              context: context,
                              useSafeArea: true,
                              builder: (context) => Column(children: [
                                    for (final room in rooms)
                                      RadioListTile(
                                        value: room,
                                        groupValue: this.room,
                                        onChanged: (Room? val) {
                                          if (val != null) {
                                            setState(() {
                                              this.room = val;
                                            });
                                            Navigator.of(context).pop();
                                          }
                                        },
                                        title: MinestrixRoomTile(
                                          room: room,
                                        ),
                                      ),
                                  ]));
                        },
                  child: MinestrixRoomTile(room: room),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (widget.shareEvent != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sharing",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  MatrixPostContent(
                      event: widget.shareEvent!,
                      imageMaxHeight: 300,
                      imageMaxWidth: 300,
                      disablePadding: true,
                      onImagePressed: (item,
                          {Event? imageEvent, String? ref}) {}),
                ],
              ),
            ),
          if (imageController.imagesToAdd.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: MatrixPostImageListEditor(
                  imageController: imageController,
                  onClose: () {
                    imageController.imagesToAdd.clear();
                    setState(() {});
                  }),
            ),
          TextField(
            minLines: 3,
            controller: _textController,
            cursorColor: Colors.grey,
            //controller: _searchController,
            onChanged: (value) {
              final isTextNotEmptyNew = value.isNotEmpty;
              if (isTextNotEmpty != isTextNotEmptyNew) {
                setState(() {
                  isTextNotEmpty = isTextNotEmptyNew;
                });
              }
            },
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(
                  Radius.circular(15),
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(
                  Radius.circular(15),
                ),
              ),
              filled: false,
              hintStyle: const TextStyle(color: Colors.grey),
              labelText: widget.sendImage ? "Image caption" : "Post content",
              labelStyle: const TextStyle(color: Colors.grey),
              alignLabelWithHint: true,
              hintText: widget.sendImage ? "Image caption" : "Post content",
            ),
            keyboardType: TextInputType.multiline,
            maxLines: null,
          ),
          if (_isEdit)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Editing post images is not possible"),
            ),
        ],
      ),
    );
  }
}
