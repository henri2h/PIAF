import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class PostEditor extends StatefulWidget {
  @override
  _PostEditorState createState() => _PostEditorState();
}

class _PostEditorState extends State<PostEditor>
    with SingleTickerProviderStateMixin {
  String postContent = "";
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text("What's up ?",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
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
          child: MarkdownBody(data:postContent),
        )
      ],
    ));
  }
}
