import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/screens/chatVue.dart';

class SMatrixRoomsVue extends StatefulWidget {
  @override
  _SMatrixRoomsVueState createState() => _SMatrixRoomsVueState();
}

class _SMatrixRoomsVueState extends State<SMatrixRoomsVue>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final sclient = Matrix.of(context).sclient;
    return Scaffold(
      appBar: AppBar(
          title: Text("Hello"),
          actions: [IconButton(icon: Icon(Icons.add), onPressed: () {})]),
      body: Container(
        child: StreamBuilder(
          stream: sclient.onSync.stream,
          builder: (context, _) => ListView.builder(
            itemCount: sclient.srooms.length,
            itemBuilder: (BuildContext context, int i) => ListTile(
              leading: CircleAvatar(
                backgroundImage: sclient.srooms[i].room.avatar == null
                    ? null
                    : NetworkImage(
                        sclient.srooms[i].room.avatar.getThumbnail(
                          sclient,
                          width: 64,
                          height: 64,
                        ),
                      ),
              ),
              title: Text(sclient.srooms[i].room.displayname),
              subtitle: Text(sclient.srooms[i].room.lastMessage),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatView(roomId: sclient.srooms[i].room.id),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
