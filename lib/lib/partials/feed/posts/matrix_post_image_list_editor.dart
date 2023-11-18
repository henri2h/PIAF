import 'package:flutter/material.dart';

import 'matrix_post_editor.dart';

class MatrixPostImageListEditor extends StatefulWidget {
  final VoidCallback onClose;
  final ImageListController imageController;
  const MatrixPostImageListEditor({
    super.key,
    required this.imageController,
    required this.onClose,
  });

  @override
  State<MatrixPostImageListEditor> createState() =>
      _MatrixPostImageListEditorState();
}

class _MatrixPostImageListEditorState extends State<MatrixPostImageListEditor> {
  @override
  Widget build(BuildContext context) {
    final images = widget.imageController.imagesToAdd;
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
                  Text("Post images",
                      style: Theme.of(context).textTheme.titleMedium),
                  IconButton(
                      icon: const Icon(Icons.close), onPressed: widget.onClose)
                ],
              ),
            ),
            Expanded(
              child: GridView(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    mainAxisExtent: 180, maxCrossAxisExtent: 200),
                children: [
                  for (var file in images)
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (file.bytes != null)
                            ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(4)),
                              child:
                                  Image.memory(file.bytes!, fit: BoxFit.cover),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
