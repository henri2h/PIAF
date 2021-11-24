import 'package:matrix/matrix.dart';
import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';
import 'package:url_launcher/url_launcher.dart';

class PostEditorPage extends StatefulWidget {
  PostEditorPage({Key? key, this.sroom}) : super(key: key);
  final MinestrixRoom? sroom;
  @override
  _PostEditorPageState createState() => _PostEditorPageState();
}

class _PostEditorPageState extends State<PostEditorPage>
    with SingleTickerProviderStateMixin {
  String postContent = "";
  FilePickerCross? file;

  MinestrixRoom? sroom;

  Future<void> sendPost(MinestrixClient sclient, String postContent,
      {Event? inReplyTo}) async {
    if (file != null) {
      MatrixFile f =
          MatrixImageFile(bytes: file!.toUint8List(), name: postContent);
      await sroom!.room.sendFileEvent(f);
    } else {
      await sroom!.room.sendTextEvent(postContent, inReplyTo: inReplyTo);
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;

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
                  MatrixUserImage(
                      client: sclient,
                      url: sclient.userRoom!.user.avatarUrl,
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
              child: Text("Post on " + sroom!.name),
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
            if (file != null) Image.memory(file!.toUint8List()),
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
              child: MarkdownBody(
                  data: postContent,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                      .copyWith(
                          blockquotePadding: const EdgeInsets.only(left: 14),
                          blockquoteDecoration: const BoxDecoration(
                              border: Border(
                                  left: BorderSide(
                                      color: Colors.white70, width: 4)))),
                  onTapLink: (text, href, title) async {
                    if (href != null) {
                      await _launchURL(href);
                    }
                  }),
            )
          ],
        ));
  }
}
