import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTheme.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/screens/chat/chatVue.dart';
import 'package:minestrix/screens/chat/conversationSettings.dart';
import 'package:timeago/timeago.dart' as timeago;

final log = Logger("ChatVue");

class ChatsVue extends StatefulWidget {
  @override
  _ChatsVueState createState() => _ChatsVueState();
}

class _ChatsVueState extends State<ChatsVue>
    with SingleTickerProviderStateMixin {
  String selectedRoomID = null;
  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 600) {
        return Row(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 350),
              child: buildChatView(context, onSelection: (String roomId) {
                setState(() {
                  selectedRoomID = roomId;
                });
              }),
            ),
            Expanded(flex: 2, child: ChatView(roomId: selectedRoomID)),
            if (selectedRoomID != null)
              ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 400),
                  child: ConversationSettings(roomId: selectedRoomID))
          ],
        );
      } else {
        return buildChatView(context, onSelection: (String roomId) {
          final Room room = sclient.getRoomById(roomId);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                  appBar: AppBar(
                    title: Text(room.displayname),
                    actions: [
                      IconButton(
                        icon: Icon(Icons.info),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) =>
                                ConversationSettings(roomId: room.id),
                          ));
                        },
                      ),
                    ],
                  ),
                  body: ChatView(roomId: roomId)),
            ),
          );
        });
      }
    });
  }

  Future<List<Room>> getRoomList(SClient client) async {
    for (Room r in client.rooms) {
      await r.postLoad();
    }
    List<Room> sortedRooms = client.rooms.where((Room r) {
      String rType =
          r.getState(EventTypes.RoomCreate)?.content?.tryGet<String>('type');
      if (rType != null) {
        if (rType != "fr.henri2h.minestrix" &&
            rType != RoomCreationTypes.mSpace)
          log.warning("Unsuported room type " +
              r.name +
              " " +
              r
                  .getState(EventTypes.RoomCreate)
                  ?.content
                  ?.tryGet<String>('type')
                  .toString() +
              " isSpace : " +
              r.isSpace.toString() +
              " won't be displayed");
        return false;
      }
      return true;

      //return !r.isSpace;
    }).toList();

    sortedRooms.sort((Room a, Room b) {
      if (a.lastEvent == null || b.lastEvent == null) {
        return 1; // we just can't do anything here..., we just throw this conversation at the end
      }
      return b.lastEvent?.originServerTs
          ?.compareTo(a.lastEvent?.originServerTs);
    });

    return sortedRooms.toList();
  }

  Widget buildChatView(BuildContext context, {@required Function onSelection}) {
    final client = Matrix.of(context).sclient;

    return FutureBuilder(
        future: getRoomList(client),
        builder: (BuildContext context, AsyncSnapshot<List<Room>> snapshot) {
          List<Room> sortedRooms = snapshot.data;
          if (snapshot.hasData)
            return StreamBuilder(
              stream: client.onSync.stream,
              builder: (context, _) => ListView.builder(
                  itemCount: sortedRooms.length + 1,
                  itemBuilder: (BuildContext context, int i) {
                    if (i == 0)
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          H1Title("MATRIX Chats"),
                          Padding(
                            padding: const EdgeInsets.all(5),
                            child: IconButton(
                                icon: Icon(Icons.add), onPressed: () {}),
                          ),
                        ],
                      );
                    int pos = i - 1;
                    return ListTile(
                        contentPadding: EdgeInsets.all(8),
                        focusColor: Colors.grey,
                        hoverColor: Colors.grey,
                        enableFeedback: true,
                        leading: MinesTrixUserImage(
                            url: sortedRooms[pos].avatar,
                            width: 50,
                            height: 50),
                        title: Text(sortedRooms[pos].displayname,
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                                sortedRooms[pos].lastEvent?.originServerTs !=
                                        null
                                    ? timeago.format(sortedRooms[pos]
                                        .lastEvent
                                        .originServerTs)
                                    : "Invalid time",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey)),
                            if (sortedRooms[pos].notificationCount != 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 15),
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
                                            sortedRooms[pos]
                                                .notificationCount
                                                .toString(),
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ),
                                    )),
                              )
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: sortedRooms[pos].lastEvent != null
                              ? Text(sortedRooms[pos].lastEvent.body,
                                  maxLines: 2)
                              : Text("Error"),
                        ),
                        onTap: () {
                          onSelection(sortedRooms[pos].id);
                        });
                  }),
            );

          return Text("Loading list");
        });
  }
}
