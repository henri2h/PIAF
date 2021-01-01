import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:minestrix/components/Theme.dart';
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
              child: FutureBuilder<Timeline>(
                future: room.getTimeline(),
                builder:
                    (BuildContext context, AsyncSnapshot<Timeline> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final timeline = snapshot.data;
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          reverse: true,
                          itemCount: timeline.events.length,
                          itemBuilder: (BuildContext context, int i) {
                            final event = timeline.events[i];
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
                                  if (sendByUser == false) SizedBox(width: 10),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: sendByUser
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Material(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.white,
                                              elevation: 0,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      vertical: 4,
                                                      horizontal: 8),
                                                  child: Text(event.body,
                                                      style: TextStyle(
                                                          color: Colors.white)),
                                                ),
                                              )),
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
                      Divider(height: 1),
                      Container(
                        height: 56,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _sendController,
                              ),
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
                    ],
                  );
                },
              ),
            ),
          );
        });
  }
}
