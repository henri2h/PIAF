import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitle("MATRIX Chats"),
        Flexible(
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
      ],
    );
  }
}
