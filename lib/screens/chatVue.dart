import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/global/matrix.dart';
import 'package:provider/provider.dart';

class ChatVue extends StatefulWidget {
  @override
  _ChatVueState createState() => _ChatVueState();
}

class _ChatVueState extends State<ChatVue> with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    return Material(
      
      child: Scaffold(
        appBar: AppBar(title:Text("Hello")),
              body: Container(
                child: Expanded(
          flex: 2,
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
                ),
            ),
          ),
        ),
              ),
      ),
    );
  }
}
