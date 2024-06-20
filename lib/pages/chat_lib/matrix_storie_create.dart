import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/stories/stories_user_selection.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../partials/utils/platform_infos.dart';
import 'device_media_gallery.dart';

@RoutePage()
class MatrixCreateStoriePage extends StatefulWidget {
  const MatrixCreateStoriePage(
      {super.key, required this.client, required this.r});

  final Client client;
  final Room r;

  @override
  MatrixCreateStoriePageState createState() => MatrixCreateStoriePageState();
}

class MatrixCreateStoriePageState extends State<MatrixCreateStoriePage> {
  PlatformFile? _img;
  final TextEditingController textController = TextEditingController();
  UserSelectionController? controller;

  Future<void> sendStory() async {
    if (_img?.bytes != null) {
      MatrixImageFile mF =
          MatrixImageFile(bytes: _img!.bytes!, name: _img?.path ?? 'null');
      await widget.r.sendFileEvent(
        mF,
        extraContent: {'body': textController.text},
      );
    }
  }

  @override
  void initState() {
    super.initState();
    textController.addListener(() {
      if ([0, 1].contains(textController.text.length)) {
        setState(() {});
      }
    });
  }

  void publish() async {
    try {
      await controller?.performUserAdditions();
      await sendStory();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Could not publish story: $e"),
        ));
      }
    }
  }

  bool get canPublish => _img != null || textController.text.isNotEmpty;

  void onImgChanged(PlatformFile? file) {
    setState(() {
      _img = file;
    });
  }

  void addImage() async {
    if (PlatformInfos.isAndroid) {
      final result = await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const DeviceMediaGallery()));
      if (result is List<AssetEntity> && result.isNotEmpty) {
        final returnedFile = await result.first.file;
        final data = await returnedFile?.readAsBytes();
        if (data != null) {
          onImgChanged(PlatformFile(
              name: result.first.title ?? '', size: data.length, bytes: data));
        }
      }
    } else {
      FilePickerResult? result = await FilePicker.platform
          .pickFiles(type: FileType.image, withData: true);

      if (result != null) {
        onImgChanged(result.files.first);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    /*
        controller ??= UserSelectionController(
        client: widget.client,
        room: widget.r,
        candidateUsers: widget.client.directChats.keys.toList());
        
         FutureBuilder<bool>(
        future: controller!.loadRoomParticipants(),
        builder: (context, snap) {
          if (!snap.hasData) return const CircularProgressIndicator();

          return UserSelection(client: widget.client, controller: controller!);
        });
        */

    return Scaffold(
      appBar: AppBar(
        title: const Text("New story"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            _img == null
                ? IconButton(
                    onPressed: addImage, icon: const Icon(Icons.add_a_photo))
                : IconButton(
                    icon: const Icon(Icons.hide_image),
                    onPressed: () {
                      onImgChanged(null);
                    })
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: canPublish ? Colors.green : null,
          onPressed: canPublish ? publish : null,
          child: const Icon(Icons.send)),
      body: Row(
        children: [
          Flexible(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                  image: _img?.bytes == null
                      ? null
                      : DecorationImage(
                          fit: BoxFit.cover, image: MemoryImage(_img!.bytes!))),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Align(
                      alignment: _img == null
                          ? Alignment.center
                          : Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: TextField(
                              maxLines: 5,
                              minLines: 3,
                              controller: textController,
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
