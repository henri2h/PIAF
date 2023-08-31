import 'package:flutter/material.dart';
import 'package:minestrix_chat/pages/chat_page.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

class HomeChatPage extends StatefulWidget {
  const HomeChatPage({Key? key}) : super(key: key);

  @override
  State<HomeChatPage> createState() => _HomeChatPageState();
}

class _HomeChatPageState extends State<HomeChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Chat view")),
        body: ChatPage(
          client: Matrix.of(context).client,
        ));
  }
}
