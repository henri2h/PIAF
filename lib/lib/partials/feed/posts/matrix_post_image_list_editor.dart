import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'matrix_post_editor.dart';

class MatrixPostImageListEditor extends StatefulWidget {
  final VoidCallback onClose;
  final ImageListController imageController;
  const MatrixPostImageListEditor({
    Key? key,
    required this.imageController,
    required this.onClose,
  }) : super(key: key);

  @override
  State<MatrixPostImageListEditor> createState() =>
      _MatrixPostImageListEditorState();
}

class _MatrixPostImageListEditorState extends State<MatrixPostImageListEditor> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Add images",
                      style: Theme.of(context).textTheme.titleMedium),
                  IconButton(
                      icon: const Icon(Icons.close), onPressed: widget.onClose)
                ],
              ),
            ),
            Wrap(
              children: [
                for (var file in widget.imageController.imagesToAdd)
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Stack(
                      children: [
                        if (file.bytes != null)
                          ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(15)),
                            child: SizedBox(
                                height: 160,
                                width: 160,
                                child: Image.memory(file.bytes!,
                                    fit: BoxFit.cover)),
                          ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  widget.imageController.imagesToAdd
                                      .remove(file);
                                });
                              }),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: SizedBox(
                    height: 160,
                    width: 160,
                    child: Card(
                        child: MaterialButton(
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles(type: FileType.image, withData: true);

                        if (result != null) {
                          PlatformFile file = result.files.first;
                          widget.imageController.imagesToAdd.add(file);
                          setState(() {});
                        }
                      },
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo, size: 42),
                            SizedBox(
                              height: 20,
                            ),
                            Text("Add a picture")
                          ],
                        ),
                      ),
                    )),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
