import 'package:matrix/matrix.dart';
import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrix/SMatrixRoom.dart';
import 'package:minestrix/global/smatrixWidget.dart';

class PostEditor extends StatefulWidget {
  PostEditor({Key key, this.sroom}) : super(key: key);
  final SMatrixRoom sroom;
  @override
  _PostEditorState createState() => _PostEditorState();
}

class _PostEditorState extends State<PostEditor>
    with SingleTickerProviderStateMixin {
  String postContent = "";
  FilePickerCross file;

  SMatrixRoom sroom;

  Future<void> sendPost(SClient sclient, String postContent,
      {Event inReplyTo}) async {
    if (file != null) {
      MatrixFile f =
          MatrixImageFile(bytes: file.toUint8List(), name: postContent);
      await sroom.room.sendFileEvent(f);
    } else {
      await sroom.room.sendTextEvent(postContent, inReplyTo: inReplyTo);
    }
  }

  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;

    sroom = widget.sroom;
    if (sroom == null) sroom = sclient.userRoom;

    return Container(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  MinesTrixUserImage(
                      url: sclient.userRoom.user.avatarUrl,
                      width: 48,
                      thumnail: true,
                      height: 48),
                  SizedBox(width: 5),
                  H1Title("What's up ?"),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Post on " + sroom.name),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                minLines: 3,
                decoration: InputDecoration(
                    border: OutlineInputBorder(), labelText: "Post content"),
                keyboardType: TextInputType.multiline,
                maxLines: null,
                onChanged: (String text) {
                  setState(() {
                    postContent = text;
                  });
                },
              ),
            ),
            Row(
              children: [
                IconButton(
                    icon: Icon(Icons.add_a_photo),
                    onPressed: () async {
                      FilePickerCross f =
                          await FilePickerCross.importFromStorage(
                              type: FileTypeCross.image);
                      setState(() {
                        file = f;
                      });
                    }),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: MinesTrixButton(
                        icon: Icons.edit,
                        label: "Send post",
                        onPressed: () {
                          sendPost(sclient, postContent);
                          Navigator.of(context).pop();
                        }),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Post preview", style: TextStyle(fontSize: 20)),
            ),
            if (file != null) Image.memory(file.toUint8List()),
            if (file != null)
              IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      file = null;
                    });
                  }),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: MarkdownBody(data: postContent),
            )
          ],
        ));
  }
}
