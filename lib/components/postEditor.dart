import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/global/smatrix.dart';
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

  SMatrixRoom sroom;

  Future<void> sendPost(SClient sclient, String postContent,
      {Event inReplyTo}) async {
    await sroom.room.sendTextEvent(postContent, inReplyTo: inReplyTo);
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
                  MinesTrixUserImage(url: sroom.user.avatarUrl),
                  SizedBox(width: 5),
                  H1Title("What's up ?"),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Post on your wall"),
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: MinesTrixButton(
                  icon: Icons.edit,
                  label: "Send post",
                  onPressed: () {
                    sendPost(sclient, postContent);
                    //Navigator.of(context).pop();
                  }),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Post preview", style: TextStyle(fontSize: 20)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: MarkdownBody(data: postContent),
            )
          ],
        ));
  }
}
