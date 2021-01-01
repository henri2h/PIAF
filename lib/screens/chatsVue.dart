import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/Theme.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/components/pageTitle.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/screens/chatVue.dart';
import 'package:timeago/timeago.dart' as timeago;

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
              if (i == 0)
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PageTitle("MATRIX Chats"),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child:
                          IconButton(icon: Icon(Icons.add), onPressed: () {}),
                    ),
                  ],
                );
              int pos = i - 1;
              return ListTile(
                contentPadding: EdgeInsets.all(8),
                focusColor: Colors.grey,
                hoverColor: Colors.grey,
                enableFeedback: true,
                leading: MatrixUserImage(
                    url: client.rooms[pos].avatar, width: 50, height: 50),
                title: Text(client.rooms[pos].displayname,
                    style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: Column(
                  children: [
                    Text(
                        timeago
                            .format(client.rooms[pos].lastEvent.originServerTs),
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                    if (client.rooms[pos].notificationCount != 0)
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Material(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                            elevation: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: MinesTrixTheme.buttonGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical:4, horizontal:8),
                                child: Text(
                                    client.rooms[pos].notificationCount
                                        .toString(),
                                    style: TextStyle(color: Colors.white)),
                              ),
                            )),
                      )
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(client.rooms[pos].lastMessage, maxLines: 2),
                ),
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
