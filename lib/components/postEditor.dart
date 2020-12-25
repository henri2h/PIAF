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
      padding: const EdgeInsets.all(8.0),
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
           child: FloatingActionButton.extended(
                        icon: const Icon(Icons.send),
                        label: Text('Send post'),
                        onPressed: () {}),
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
