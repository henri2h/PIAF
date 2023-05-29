import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/feed/minestrix_room_tile.dart';
import 'package:minestrix_chat/utils/extensions/minestrix/posts_event_extension.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../utils/extensions/minestrix/model/social_item.dart';
import '../../dialogs/adaptative_dialogs.dart';
import '../../matrix/matrix_image_avatar.dart';
import 'matrix_post_content.dart';
import 'matrix_post_image_list_editor.dart';

class PostEditorPage extends StatefulWidget {
  /// Allow creating or editing a post. In case of edition, don't forgot to set also the eventToEdit parameter
  /// so we know which event to edit and give the latest event to post so we can display the latests edits.
  const PostEditorPage(
      {Key? key,
      this.room,
      this.post,
      this.eventToEditId,
      this.shareEvent,
      this.sendImage = false})
      : assert(room != null || post != null),
        super(key: key);
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
    await AdaptativeDialogs.show(
        context: context,
        title: "Share post",
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
        title: "Create post",
        builder: (context) =>
            PostEditorPage(post: event, eventToEditId: eventToEdit?.eventId));
  }

  @override
  PostEditorPageState createState() => PostEditorPageState();
}

class ImageListController {
  List<PlatformFile> imagesToAdd = [];
}

class PostEditorPageState extends State<PostEditorPage>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final imageController = ImageListController();
  final List<String> imagesRefEventId = [];

  bool _sending = false;
  bool get _isEdit => post != null;

  List<Room> get rooms => widget.room ?? [room];

  bool displayImageListEditor = false;

  Future<void> _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

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

    for (var file in imageController.imagesToAdd) {
      if (file.bytes == null) {
        continue;
      }
      var img =
          await MatrixImageFile.shrink(bytes: file.bytes!, name: file.name);

      final imageEventId = await room.sendFileEvent(img);

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

  @override
  Widget build(BuildContext context) {
    Client client = room.client;

    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Expanded(
              child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: TabBarView(
                    children: [
                      ListView(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Text("Post on",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          rooms.length > 1
                              ? DropdownButton<Room>(
                                  value: room,
                                  icon: const Icon(Icons.arrow_downward),
                                  elevation: 16,
                                  itemHeight: 60,
                                  isExpanded: true,
                                  underline: Container(),
                                  onChanged: (Room? room) {
                                    if (room != null) {
                                      setState(() {
                                        this.room = room;
                                      });
                                    }
                                  },
                                  items: rooms
                                      .map<DropdownMenuItem<Room>>((Room room) {
                                    return DropdownMenuItem<Room>(
                                        value: room,
                                        child: MinestrixRoomTile(room: room));
                                  }).toList(),
                                )
                              : MinestrixRoomTile(room: room),
                          const SizedBox(height: 12),
                          if (widget.shareEvent != null)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Sharing",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<Profile>(
                                  future: client
                                      .getProfileFromUserId(client.userID!),
                                  builder: (context, snap) {
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: MatrixImageAvatar(
                                          client: client,
                                          url: snap.data?.avatarUrl,
                                          defaultText: snap.data?.displayName,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary),
                                    );
                                  }),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: TextField(
                                    minLines: 3,
                                    controller: _textController,
                                    cursorColor: Colors.grey,
                                    //controller: _searchController,
                                    onChanged: (value) {
                                      final isTextNotEmptyNew =
                                          value.isNotEmpty;
                                      if (isTextNotEmpty != isTextNotEmptyNew) {
                                        setState(() {
                                          isTextNotEmpty = isTextNotEmptyNew;
                                        });
                                      }
                                    },
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 15, horizontal: 12),
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
                                      prefixIcon: const Icon(Icons.edit,
                                          color: Colors.grey),
                                      filled: true,
                                      hintStyle:
                                          const TextStyle(color: Colors.grey),
                                      labelText: widget.sendImage
                                          ? "Image caption"
                                          : "Post content",
                                      labelStyle:
                                          const TextStyle(color: Colors.grey),
                                      alignLabelWithHint: true,
                                      hintText: widget.sendImage
                                          ? "Image caption"
                                          : "Post content",
                                    ),
                                    keyboardType: TextInputType.multiline,
                                    maxLines: null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_isEdit)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child:
                                  Text("Editing post images is not possible"),
                            ),
                          if (displayImageListEditor)
                            MatrixPostImageListEditor(
                                imageController: imageController,
                                onClose: () {
                                  setState(() {
                                    displayImageListEditor = false;
                                  });
                                })
                        ],
                      ),
                      ListView(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Text preview",
                                style: TextStyle(fontSize: 20)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: MarkdownBody(
                                data: _textController.text,
                                styleSheet: MarkdownStyleSheet.fromTheme(
                                        Theme.of(context))
                                    .copyWith(
                                        blockquotePadding:
                                            const EdgeInsets.only(left: 14),
                                        blockquoteDecoration:
                                            const BoxDecoration(
                                                border: Border(
                                                    left: BorderSide(
                                                        color: Colors.white70,
                                                        width: 4)))),
                                onTapLink: (text, href, title) async {
                                  if (href != null) {
                                    await _launchURL(Uri.parse(href));
                                  }
                                }),
                          ),
                        ],
                      )
                    ],
                  )),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Card(
                  child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isEdit)
                      MaterialButton(
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8))),
                          onPressed: displayImageListEditor
                              ? null
                              : () {
                                  setState(() {
                                    displayImageListEditor =
                                        !displayImageListEditor;
                                  });
                                },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 12),
                            child: Row(
                              children: const [
                                Icon(Icons.add_a_photo),
                                SizedBox(width: 10),
                                Text("Add a picture"),
                              ],
                            ),
                          )),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TabBar(
                          tabs: [
                            Tab(
                                icon: Icon(Icons.edit,
                                    color:
                                        Theme.of(context).colorScheme.primary)),
                            Tab(
                                icon: Icon(Icons.preview,
                                    color:
                                        Theme.of(context).colorScheme.primary)),
                          ],
                        ),
                      ),
                    ),
                    Card(
                        color: !canSend ? Colors.grey : Colors.green,
                        child: IconButton(
                            icon: _sending
                                ? const Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.white))
                                : Icon(_isEdit ? Icons.edit : Icons.send,
                                    color: Colors.white),
                            onPressed: canSend ? sendPost : null))
                  ],
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}
