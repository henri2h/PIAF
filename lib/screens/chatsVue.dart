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
    List<Room> sortedRooms = client.rooms.toList();
    sortedRooms.sort((Room a, Room b) =>
        b.lastEvent.originServerTs.compareTo(a.lastEvent.originServerTs));
    return Flexible(
      child: StreamBuilder(
        stream: client.onSync.stream,
        builder: (context, _) => ListView.builder(
            itemCount: sortedRooms.length + 1,
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
                    url: sortedRooms[pos].avatar, width: 50, height: 50),
                title: Text(sortedRooms[pos].displayname,
                    style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                        timeago
                            .format(sortedRooms[pos].lastEvent.originServerTs),
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                    if (sortedRooms[pos].notificationCount != 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical:4, horizontal:15),
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
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                child: Text(
                                    sortedRooms[pos].notificationCount
                                        .toString(),
                                    style: TextStyle(color: Colors.white)),
                              ),
                            )),
                      )
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(sortedRooms[pos].lastMessage, maxLines: 2),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatView(roomId: sortedRooms[pos].id),
                  ),
                ),
              );
            }),
      ),
    );
  }
}
