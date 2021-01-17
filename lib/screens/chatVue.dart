import 'package:famedlysdk/famedlysdk.dart';
import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minestrix/components/matrix/mMessageDisplay.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatView extends StatelessWidget {
  final String roomId;

  const ChatView({Key key, @required this.roomId}) : super(key: key);

  Future getImage() async {
    final pickedFile = await ImagePicker().getImage(source: ImageSource.camera);

    if (pickedFile != null) {
      print(pickedFile.path);
    } else {
      print('No image selected.');
    }
  }

  void sendImage(BuildContext context, Room room) async {
    final file =
        await FilePickerCross.importFromStorage(type: FileTypeCross.image);
    if (file == null) return;
    MatrixFile f =
        MatrixImageFile(bytes: file.toUint8List(), name: "pomme de terre");
    room.sendFileEvent(f);
  }

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
          print(sclient.encryption?.crossSigning?.enabled);

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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (sendByUser == false)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 6.0),
                                        child: MinesTrixUserImage(
                                            url: sender.avatarUrl,
                                            width: 40,
                                            height: 40,
                                            thumnail: true,
                                            fit: true),
                                      ),
                                    if (sendByUser == false) SizedBox(width: 8),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: sendByUser
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        children: [
                                          ConstrainedBox(
                                            constraints:
                                                BoxConstraints(maxWidth: 280),
                                            child: MessageDisplay(
                                                event: event,
                                                widgetDisplay: (String data) {
                                                  return Card(
                                                      color: Colors.blue,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .symmetric(
                                                                  vertical: 10,
                                                                  horizontal:
                                                                      16),
                                                          child: MarkdownBody(
                                                            data: data,
                                                            styleSheet: MarkdownStyleSheet
                                                                    .fromTheme(
                                                                        Theme.of(
                                                                            context))
                                                                .copyWith(
                                                                    p: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .bodyText1
                                                                        .copyWith(
                                                                            color:
                                                                                Colors.white)),
                                                          )));
                                                }),
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
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                FloatingActionButton(
                                  onPressed: () {
                                    sendImage(context, room);
                                  },
                                  tooltip: 'Send file',
                                  child: Icon(Icons.file_upload),
                                ),
                                SizedBox(width: 5),
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
