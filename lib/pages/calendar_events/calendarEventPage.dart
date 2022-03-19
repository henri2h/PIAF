import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/buttons/customFutureButton.dart';
import 'package:minestrix/partials/components/layouts/customHeader.dart';
import 'package:minestrix/partials/post/postView.dart';
import 'package:minestrix_chat/partials/feed/posts/matrix_post_editor.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';
import 'package:minestrix_chat/utils/poll/poll.dart';
import 'package:minestrix_chat/utils/social/calendar_events/calendar_events_extension.dart';
import 'package:minestrix_chat/partials/calendar_event/calendarEventWidget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:minestrix_chat/partials/social/social_gallery_preview_widget.dart';
import 'package:minestrix_chat/utils/social/posts/posts_event_extension.dart';

class CalendarEventPage extends StatefulWidget {
  final Room room;
  const CalendarEventPage({Key? key, required this.room}) : super(key: key);

  @override
  _CalendarEventPageState createState() => _CalendarEventPageState();
}

class _CalendarEventPageState extends State<CalendarEventPage> {
  late Future<Timeline> timeline;
  Future<Timeline> load() async {
    await widget.room.postLoad();
    return widget.room.getTimeline();
  }

  @override
  void initState() {
    super.initState();
    timeline = load();
  }

  @override
  Widget build(BuildContext context) {
    Room room = widget.room;
    return SafeArea(
      child: FutureBuilder<Timeline>(
          future: timeline,
          builder: (context, snapT) {
            return StreamBuilder<Object>(
                stream: room.client.onSync.stream,
                builder: (context, snapshot) {
                  return ListView(
                    children: [
                      CustomHeader("Event"),
                      MatrixUserImage(
                        client: room.client,
                        url: room.avatar,
                        width: 2000,
                        rounded: false,
                        height: 250,
                        defaultText: room.name,
                        thumnail:
                            false, // we don't use thumnail as this picture is from weird dimmension and preview generation don't work well
                        backgroundColor: Colors.blue,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 800),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(room.name,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22)),
                                  ),
                                  snapT.hasData
                                      ? FutureBuilder<Event?>(
                                          future:
                                              room.getEventAttendanceEvent(),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData == false)
                                              return Container();

                                            Poll p = Poll(
                                                e: snapshot.data!,
                                                t: snapT.data!);
                                            return CalendarEventWidget(p: p);
                                          })
                                      : CircularProgressIndicator(),
                                  Card(
                                      child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: MarkdownBody(
                                        data: room.topic,
                                        onTapLink: (text, href, title) async {
                                          if (href != null) {
                                            if (await canLaunch(href)) {
                                              await launch(href);
                                            } else {
                                              throw 'Could not launch $href';
                                            }
                                          }
                                        }),
                                  )),
                                ],
                              ),
                            ),
                            if (snapT.hasData)
                              ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: 800),
                                  child: Column(
                                    children: [
                                      SocialGalleryPreviewWigdet(
                                          room: room, timeline: snapT.data!),
                                      for (Event e
                                          in room.getPosts(snapT.data!))
                                        Post(
                                            event: e,
                                            onReact: (Offset e) {},
                                            timeline: snapT.data),
                                      MaterialButton(
                                          child: const Text("Write a post"),
                                          onPressed: () async {
                                            await showDialog(
                                                context: context,
                                                builder: ((context) => Dialog(
                                                    child: PostEditorPage(
                                                        room: room))));
                                          })
                                    ],
                                  )),
                          ],
                        ),
                      ),
                      if (snapT.hasData)
                        CustomFutureButton(
                            onPressed: () async {
                              await snapT.data!.requestHistory();
                            },
                            children: [Text("Refresh")],
                            icon: Icon(Icons.refresh))
                    ],
                  );
                });
          }),
    );
  }
}
