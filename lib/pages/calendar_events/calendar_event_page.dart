import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/components/minestrix/minestrix_title.dart';
import 'package:piaf/config/matrix_types.dart';
import 'package:piaf/partials/minestrix_chat.dart';
import 'package:piaf/partials/calendar_event/calendar_event_widget.dart';
import 'package:piaf/partials/chat/room/room_participants_indicator.dart';
import 'package:piaf/partials/chat/user/selector/user_selector_dialog.dart';
import 'package:piaf/partials/chat/user/user_item.dart';
import 'package:piaf/partials/social/social_gallery_preview_widget.dart';
import 'package:piaf/partials/utils/extensions/minestrix/model/calendar_event_model.dart';
import 'package:piaf/partials/utils/poll/poll.dart';

import '../../partials/calendar_events/datetime_tile.dart';
import '../../partials/calendar_events/duration_widget.dart';
import '../../partials/components/layouts/layout_view.dart';
import '../../partials/feed/topic_list_tile.dart';
import '../../partials/post/post.dart';
import '../../partials/post/post_shimmer.dart';
import '../../partials/post/post_writer_modal.dart';
import '../../router.gr.dart';

@RoutePage()
class CalendarEventPage extends StatefulWidget {
  final Room room;
  const CalendarEventPage({super.key, required this.room});

  @override
  CalendarEventPageState createState() => CalendarEventPageState();
}

class CalendarEventPageState extends State<CalendarEventPage> {
  late Future<Timeline> timeline;

  final controller = ScrollController();
  bool loading = false;

  Future<Timeline> load() async {
    await widget.room.postLoad();
    final t = await widget.room.getTimeline();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      // request timeline history if needed
      while ((t.canRequestHistory) &&
          controller.hasClients &&
          controller.position.hasContentDimensions &&
          controller.position.maxScrollExtent == 0) {
        if (t.isRequestingHistory) {
          if (!mounted) return;
          Future.delayed(const Duration(milliseconds: 200));
        } else {
          await t.requestHistory();
        }
      }
    });
    return t;
  }

  @override
  void initState() {
    super.initState();
    timeline = load();
    controller.addListener(onScroll);
  }

  Future<void> onScroll() async {
    final t = await timeline;

    if (t.canRequestHistory && mounted) {
      setState(() {
        loading = true;
      });
      await t.requestHistory();
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> inviteUsers() async {
    List<String>? userIds =
        await MinesTrixUserSelection.show(context, widget.room);

    userIds?.forEach((String userId) async {
      await widget.room.invite(userId);
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Room room = widget.room;
    return Scaffold(
      appBar: AppBar(
        title: Text(room.name),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  context.navigateTo(SocialSettingsRoute(room: room));
                }),
          ),
        ],
      ),
      body: FutureBuilder<Timeline>(
          future: timeline,
          builder: (context, snapT) {
            final calendarEvent = room.getEventAttendanceEvent();
            return StreamBuilder<Object>(
                stream: room.onRoomInSync(),
                builder: (context, snapshot) {
                  return LayoutView(
                      controller: controller,
                      room: room,
                      headerHeight: 280,
                      mainWidth: double.infinity,
                      mainBuilder: (
                              {required bool displaySideBar,
                              required bool displayLeftBar}) =>
                          Column(
                            children: [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Card(
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 1200),
                                      child: Description(
                                          room: room,
                                          onInvite: inviteUsers,
                                          calendarEvent: calendarEvent),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  children: [
                                    if (snapT.hasData)
                                      ConstrainedBox(
                                          constraints: const BoxConstraints(
                                              maxWidth: 600),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Card(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: AttendancePollCard(
                                                          snapT: snapT,
                                                          calendarEvent:
                                                              calendarEvent,
                                                          room: room),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              PostWriterModal(room: room),
                                              for (Event e in room.getPosts(
                                                  snapT.data!,
                                                  eventTypesFilter: [
                                                    MatrixTypes.post,
                                                    EventTypes.Encrypted,
                                                    EventTypes.RoomCreate
                                                  ]))
                                                Post(
                                                    event: e,
                                                    onReact: (Offset e) {},
                                                    timeline: snapT.data),
                                              if (loading) const PostShimmer(),
                                            ],
                                          )),
                                    if (snapT.hasData)
                                      ConstrainedBox(
                                          constraints: const BoxConstraints(
                                              maxWidth: 450),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: CalendarGallery(
                                              room: room,
                                              timeline: snapT.data!,
                                            ),
                                          )),
                                  ],
                                ),
                              ),
                            ],
                          ));
                });
          }),
    );
  }
}

class AttendancePollCard extends StatelessWidget {
  const AttendancePollCard(
      {super.key,
      required this.calendarEvent,
      required this.room,
      required this.snapT});

  final CalendarEvent? calendarEvent;
  final Room room;
  final AsyncSnapshot<Timeline> snapT;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        (snapT.hasData && calendarEvent?.pollId != null)
            ? FutureBuilder<Event?>(
                future: snapT.data!.getEventById(calendarEvent!.pollId!),
                builder: (context, snapshot) {
                  if (snapshot.hasData == false) {
                    return Container();
                  }

                  Poll p = Poll(e: snapshot.data!, t: snapT.data!);
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: CalendarEventWidget(p: p),
                  );
                })
            : ListTile(
                leading: const Icon(Icons.poll),
                title: const Text("Set poll id"),
                subtitle: Text(room.canSendDefaultStates
                    ? "Attendance poll could not be found"
                    : "You don't have the permission to modify this event"),
                onTap: !room.canSendDefaultStates
                    ? null
                    : () async {
                        if (calendarEvent != null) {
                          await room.setPollAttendance(calendarEvent!);
                        } else {
                          await room.setPollAttendance(CalendarEvent());
                        }
                      }),
      ],
    );
  }
}

class CalendarGallery extends StatelessWidget {
  const CalendarGallery(
      {super.key, required this.room, required this.timeline});

  final Room room;
  final Timeline timeline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const H2Title("Images"),
        SocialGalleryPreviewWigdet(room: room, timeline: timeline),
      ],
    );
  }
}

class Description extends StatelessWidget {
  const Description(
      {super.key,
      required this.room,
      required this.calendarEvent,
      required this.onInvite});

  final Room room;

  final CalendarEvent? calendarEvent;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        H2Title(room.name),
        if (room.topic.isNotEmpty)
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: TopicBody(
                room: room,
              )),
        Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 10, right: 4),
              child: Text("By",
                  style:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: UserItem.fromUser(room.creator!, client: room.client),
            ),
          ],
        ),
        if (calendarEvent != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                  leading: room.joinRules == JoinRules.public
                      ? const Icon(Icons.public)
                      : const Icon(Icons.lock),
                  title: Text(room.joinRules == JoinRules.public
                      ? "Public event"
                      : "Private event")),
              if (room.encrypted)
                const ListTile(
                    leading: Icon(Icons.enhanced_encryption),
                    title: Text("Encryption enabled")),
              if (calendarEvent!.place != null)
                ListTile(
                  title: Text(calendarEvent!.place!),
                  leading: const Icon(Icons.location_on),
                ),
              if (calendarEvent?.start != null)
                DateTimeTile(text: "Start time", date: calendarEvent!.start!),

              // If the duration is less than a day, we display the event duration
              // else we display the event end date
              if (calendarEvent?.duration != Duration.zero)
                calendarEvent!.duration.inHours < 24
                    ? DurationWidget(calendarEvent: calendarEvent!)
                    : DateTimeTile(text: "End", date: calendarEvent!.end!),
            ],
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: RoomParticipantsIndicator(room: room),
              ),
              ElevatedButton(
                  onPressed: onInvite,
                  child: const Row(
                    children: [
                      Icon(Icons.person_add),
                      SizedBox(width: 8),
                      Text("Invite"),
                    ],
                  ))
            ],
          ),
        )
      ],
    );
  }
}
