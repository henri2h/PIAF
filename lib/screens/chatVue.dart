
import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:minestrix/global/matrix.dart';

class ChatView extends StatelessWidget {
  final String roomId;

  const ChatView({Key key, @required this.roomId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    final TextEditingController _sendController = TextEditingController();
    return StreamBuilder<Object>(
        stream: client.onSync.stream,
        builder: (context, _) {
          final room = client.getRoomById(roomId);
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
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: sender.avatarUrl == null
                                    ? null
                                    : NetworkImage(
                                        sender.avatarUrl.getThumbnail(
                                          client,
                                          width: 64,
                                          height: 64,
                                        ),
                                      ),
                              ),
                              title: Text(sender.calcDisplayname()),
                              subtitle: Text(event.body),
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
