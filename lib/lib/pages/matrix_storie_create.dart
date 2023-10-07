import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/mobile_stepper/mobile_stepper.dart';
import 'package:minestrix_chat/partials/stories/stories_user_selection.dart';

class MatrixCreateStoriePage extends StatefulWidget {
  const MatrixCreateStoriePage(
      {Key? key, required this.client, required this.r})
      : super(key: key);

  final Client client;
  final Room r;

  @override
  MatrixCreateStoriePageState createState() => MatrixCreateStoriePageState();
}

class MatrixCreateStoriePageState extends State<MatrixCreateStoriePage> {
  PlatformFile? _img;
  final TextEditingController _t = TextEditingController();
  UserSelectionController? controller;

  Future<void> send() async {
    if (_img?.bytes != null) {
      MatrixImageFile mF =
          MatrixImageFile(bytes: _img!.bytes!, name: _img?.path ?? 'null');
      await widget.r.sendFileEvent(
        mF,
        extraContent: {'body': _t.text},
      );
    }
  }

  void publish() async {
    await controller!.performUserAdditions();
    await send();

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    controller ??= UserSelectionController(
        client: widget.client,
        room: widget.r,
        candidateUsers: widget.client.directChats.keys.toList());
    return StorieContentCreator(
        img: _img,
        textController: _t,
        onImgChanged: (file) => setState(() {
              _img = file;
            }));

    FutureBuilder<bool>(
        future: controller!.loadRoomParticipants(),
        builder: (context, snap) {
          if (!snap.hasData) return const CircularProgressIndicator();

          return UserSelection(client: widget.client, controller: controller!);
        });
  }
}

class StorieContentCreator extends StatefulWidget {
  final PlatformFile? img;
  final void Function(PlatformFile? file) onImgChanged;
  final TextEditingController textController;
  const StorieContentCreator(
      {Key? key,
      required this.onImgChanged,
      required this.textController,
      required this.img})
      : super(key: key);

  @override
  StorieContentCreatorState createState() => StorieContentCreatorState();
}

class StorieContentCreatorState extends State<StorieContentCreator> {
  void addImage() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);

    if (result != null) {
      widget.onImgChanged(result.files.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New story"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            widget.img == null
                ? IconButton(
                    onPressed: addImage, icon: const Icon(Icons.add_a_photo))
                : IconButton(
                    icon: const Icon(Icons.hide_image),
                    onPressed: () {
                      widget.onImgChanged(null);
                    })
          ],
        ),
      ),
      floatingActionButton:
          FloatingActionButton(onPressed: () {}, child: const Icon(Icons.send)),
      body: Row(
        children: [
          Flexible(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                  image: widget.img?.bytes == null
                      ? null
                      : DecorationImage(
                          fit: BoxFit.cover,
                          image: MemoryImage(widget.img!.bytes!))),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Align(
                      alignment: widget.img == null
                          ? Alignment.center
                          : Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: TextField(
                              maxLines: 5,
                              minLines: 3,
                              controller: widget.textController,
                              keyboardType: TextInputType.multiline,
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 15, horizontal: 12),
                                border: InputBorder.none,
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
                                prefixIcon: const Icon(Icons.message,
                                    color: Colors.grey),
                                hintStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Theme.of(context)
                                    .cardColor
                                    .withOpacity(0.9),
                                hintText: "What's up today ?",
                              )),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
