import 'package:famedlysdk/famedlysdk.dart';
import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minestrix/components/matrix/mMessageDisplay.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/screens/conversationSettings.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatView extends StatefulWidget {
  const ChatView({Key key, @required this.roomId}) : super(key: key);

  final String roomId;
  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  int reloadedCount = 0;
  int roomUpdate = 0;
  Timeline timeline;

  bool updating = false;
  void scrollListener() async {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (updating == false) {
        setState(() {
          updating = true;
        });
        print("update");
        await timeline.requestHistory();
        setState(() {
          updating = false;
        });
      }
    }
  }

  // scrolling logic
  ScrollController _scrollController = new ScrollController();
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(scrollListener);
  }

  @override
  void deactivate() {
    super.deactivate();
    _scrollController.removeListener(scrollListener);
  }

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
        MatrixImageFile(bytes: file.toUint8List(), name: file.fileName);
    await room.sendFileEvent(f);
  }

  @override
  Widget build(BuildContext context) {
    final sclient = Matrix.of(context).sclient;
    final TextEditingController _sendController = TextEditingController();

    reloadedCount++;

    final Room room = sclient.getRoomById(widget.roomId);
    return StreamBuilder<String>(
        stream: room.onUpdate.stream,
        builder: (context, AsyncSnapshot<String> snapshot) {
          return Scaffold(
            appBar: AppBar(
              title: Text(room.displayname),
              actions: [
                IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ConversationSettings(room: room),
                    ));
                  },
                ),
              ],
            ),
            body: SafeArea(
              child: ColoredBox(
                color: Colors.white,
                child: FutureBuilder<Timeline>(
                  future: room.getTimeline(onUpdate: () {
                    setState(() {
                      roomUpdate++;
                    });
                  }),
                  builder:
                      (BuildContext context, AsyncSnapshot<Timeline> snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    timeline = snapshot.data;
                    List<Event> filteredEvents = timeline.events
                        .where((e) => !{
                              RelationshipTypes.Edit,
                              RelationshipTypes.Reaction
                            }.contains(e.relationshipType))
                        .toList();

                    return Column(
                      children: [
                        if (updating) CircularProgressIndicator(),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              print("refresh");
                            },
                            backgroundColor: Colors.teal,
                            color: Colors.white,
                            displacement: 200,
                            strokeWidth: 5,
                            child: ListView.builder(
                              controller: _scrollController,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (sendByUser == false)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 4, top: 6.0),
                                          child: MinesTrixUserImage(
                                              url: sender.avatarUrl,
                                              width: 40,
                                              height: 40,
                                              thumnail: true,
                                              fit: true),
                                        ),
                                      if (sendByUser == false)
                                        SizedBox(width: 8),
                                      Flexible(
                                        child: Column(
                                          crossAxisAlignment: sendByUser
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: [
                                            if (sendByUser == false)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 10.0),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                        sender
                                                            .calcDisplayname(),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    Text(" - ",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.grey)),
                                                    Text(
                                                        timeago.format(event
                                                            .originServerTs),
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.grey)),
                                                  ],
                                                ),
                                              ),
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
                                                                    vertical:
                                                                        10,
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
                                                                              color: Colors.white)),
                                                            )));
                                                  }),
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
                        ),
                        Container(
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  sendImage(context, room);
                                },
                                tooltip: 'Send file',
                                icon: Icon(Icons.image_outlined),
                              ),
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: TextField(
                                      maxLines: 1,
                                      controller: _sendController,
                                      keyboardType: TextInputType.text,
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 15, horizontal: 12),
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
                                                color: Colors.blue, width: 2.0),
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
                              ),
                              IconButton(
                                icon: Icon(Icons.send),
                                onPressed: () {
                                  if (_sendController.text != "") {
                                    room.sendTextEvent(_sendController.text);
                                    _sendController.clear();
                                  }
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
            ),
          );
        });
  }
}
