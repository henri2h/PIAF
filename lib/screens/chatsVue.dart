import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/components/pageTitle.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/screens/chatVue.dart';

class ChatsVue extends StatefulWidget {
  @override
  _ChatsVueState createState() => _ChatsVueState();
}

class _ChatsVueState extends State<ChatsVue>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).sclient;
    return Flexible(
      child: StreamBuilder(
        stream: client.onSync.stream,
        builder: (context, _) => ListView.builder(
            itemCount: client.rooms.length + 1,
            itemBuilder: (BuildContext context, int i) {
              if (i == 0) return PageTitle("MATRIX Chats");
              int pos = i - 1;
              return ListTile(
                leading: MatrixUserImage(url: client.rooms[pos].avatar),
                title: Text(client.rooms[pos].displayname),
                subtitle: Text(client.rooms[pos].lastMessage),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatView(roomId: client.rooms[pos].id),
                  ),
                ),
              );
            }),
      ),
    );
  }
}
