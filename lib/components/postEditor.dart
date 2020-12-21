import 'package:flutter/material.dart';

class PostEditor extends StatefulWidget {
  @override
  _PostEditorState createState() => _PostEditorState();
}

class _PostEditorState extends State<PostEditor>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
      children: [Text("Hello"), TextField()],
    ));
  }
}
