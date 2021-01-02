import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:minestrix/components/Theme.dart';
import 'package:minestrix/components/matrix/mMessageDisplay.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatView extends StatelessWidget {
  final String roomId;

  const ChatView({Key key, @required this.roomId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sclient = Matrix.of(context).sclient;
    final TextEditingController _sendController = TextEditingController();
    return StreamBuilder<Object>(
        stream: sclient.onSync.stream,
        builder: (context, _) {
          final room = sclient.getRoomById(roomId);

          print("Encryption :");
          print(room.encrypted);
          print(sclient.encryptionEnabled);
          print(sclient.encryption.crossSigning.enabled);

          return Scaffold(
            appBar: AppBar(
              title: Text(room.displayname),
            ),
            body: SafeArea(
              child: ColoredBox(
                color: Colors.white,
                child: FutureBuilder<Timeline>(
                  future: room.getTimeline(),
                  builder:
                      (BuildContext context, AsyncSnapshot<Timeline> snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final timeline = snapshot.data;
                    List<Event> filteredEvents =
                        sclient.getSRoomFilteredEvents(timeline);
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            reverse: true,
                            itemCount: filteredEvents.length,
                            itemBuilder: (BuildContext context, int i) {
                              final event = filteredEvents[i];
                              final sender = event.sender;
                              bool sendByUser = sender.id == sclient.userID;

                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: sendByUser
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  children: [
                                    if (sendByUser == false)
                                      MatrixUserImage(
                                          url: sender.avatarUrl,
                                          width: 40,
                                          height: 40),
                                    if (sendByUser == false)
                                      SizedBox(width: 10),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: sendByUser
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.blue,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 6,
                                                        horizontal: 12),
                                                child: MessageDisplay(event:event)
                                              ),
                                            ),
                                          ),
                                          if (sendByUser == false)
                                            Row(
                                              children: [
                                                Text(sender.calcDisplayname(),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text(" - ",
                                                    style: TextStyle(
                                                        color: Colors.grey)),
                                                Text(
                                                    timeago.format(
                                                        event.originServerTs),
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey)),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              left: 20, right: 20, bottom: 5, top: 5),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    maxLines: null,
                                      controller: _sendController,
                                      keyboardType: TextInputType.multiline,
                                      decoration: InputDecoration(
                                          border: InputBorder.none,
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.white, width: 0),
                                            borderRadius:
                                                const BorderRadius.all(
                                              const Radius.circular(20),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.blue, width: 3.0),
                                            borderRadius:
                                                const BorderRadius.all(
                                              const Radius.circular(20),
                                            ),
                                          ),
                                          filled: true,
                                          hintStyle: new TextStyle(
                                              color: Colors.grey[800]),
                                          hintText: "Message",
                                          fillColor: Color(0xfff6f8fd))),
                                ),
                                IconButton(
                                  icon: Icon(Icons.send),
                                  onPressed: () {
                                    room.sendTextEvent(_sendController.text);
                                    _sendController.clear();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        });
  }
}
