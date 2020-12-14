import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/global/matrix.dart';
import 'package:minestrix/screens/chatVue.dart';
import 'package:provider/provider.dart';

class ChatsVue extends StatefulWidget {
  @override
  _ChatsVueState createState() => _ChatsVueState();
}

class _ChatsVueState extends State<ChatsVue>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    return Scaffold(
      appBar: AppBar(
          title: Text("Hello"),
          actions: [IconButton(icon: Icon(Icons.add), onPressed: () {})]),
      body: Container(
        child: StreamBuilder(
          stream: client.onSync.stream,
          builder: (context, _) => ListView.builder(
            itemCount: client.rooms.length,
            itemBuilder: (BuildContext context, int i) => ListTile(
              leading: CircleAvatar(
                backgroundImage: client.rooms[i].avatar == null
                    ? null
                    : NetworkImage(
                        client.rooms[i].avatar.getThumbnail(
                          client,
                          width: 64,
                          height: 64,
                        ),
                      ),
              ),
              title: Text(client.rooms[i].displayname),
              subtitle: Text(client.rooms[i].lastMessage),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatView(roomId: client.rooms[i].id),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
