import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/layouts/custom_header.dart';
import 'package:minestrix/partials/components/minestrix/minestrix_title.dart';
import 'package:minestrix/partials/post/post.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/partials/calendar_event/calendar_event_widget.dart';
import 'package:minestrix_chat/partials/chat/room/room_participants_indicator.dart';
import 'package:minestrix_chat/partials/chat/user/user_selector_dialog.dart';
import 'package:minestrix_chat/partials/matrix/matrix_user_item.dart';
import 'package:minestrix_chat/partials/social/social_gallery_preview_widget.dart';
import 'package:minestrix_chat/utils/extensions/minestrix/model/calendar_event_model.dart';
import 'package:minestrix_chat/utils/poll/poll.dart';

import '../../partials/calendar_events/datetime_tile.dart';
import '../../partials/calendar_events/duration_widget.dart';
import '../../partials/components/layouts/layout_view.dart';
import '../../partials/feed/topic_list_tile.dart';
import '../../partials/post/post_writer_modal.dart';
import '../../router.gr.dart';

class CalendarEventPage extends StatefulWidget {
  final Room room;
  const CalendarEventPage({Key? key, required this.room}) : super(key: key);

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
    return SafeArea(
      child: FutureBuilder<Timeline>(
          future: timeline,
          builder: (context, snapT) {
            final calendarEvent = room.getEventAttendanceEvent();
            return StreamBuilder<Object>(
                stream: room.onRoomInSync(),
                builder: (context, snapshot) {
                  return LayoutView(
                      controller: controller,
                      customHeader: CustomHeader(
                        title: "Event",
                        actionButton: [
                          IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                context
                                    .pushRoute(SocialSettingsRoute(room: room));
                              }),
                        ],
                      ),
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
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                H2Title(room.name),
                                                Row(
                                                  children: [
                                                    const Padding(
                                                      padding: EdgeInsets.only(
                                                          left: 10, right: 4),
                                                      child: Text("By",
                                                          style: TextStyle(
                                                              fontSize: 18.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500)),
                                                    ),
                                                    Expanded(
                                                      child: MatrixUserItem
                                                          .fromUser(
                                                              room.creator!,
                                                              client:
                                                                  room.client),
                                                    ),
                                                  ],
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child:
                                                            RoomParticipantsIndicator(
                                                                room: room),
                                                      ),
                                                      ElevatedButton(
                                                          onPressed:
                                                              inviteUsers,
                                                          child: Row(
                                                            children: const [
                                                              Icon(Icons
                                                                  .person_add),
                                                              SizedBox(
                                                                  width: 8),
                                                              Text("Invite"),
                                                            ],
                                                          ))
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
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
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Card(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const H2Title("About"),
                                                      if (room.topic.isNotEmpty)
                                                        Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(16.0),
                                                            child: TopicBody(
                                                              room: room,
                                                            )),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(16.0),
                                                        child: AttendancePollCard(
                                                            snapT: snapT,
                                                            calendarEvent:
                                                                calendarEvent,
                                                            room: room),
                                                      ),
                                                    ],
                                                  ),
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
                                    if (snapT.hasData && calendarEvent != null)
                                      ConstrainedBox(
                                          constraints: const BoxConstraints(
                                              maxWidth: 450),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: CalendarEventInfo(
                                                room: room,
                                                timeline: snapT.data!,
                                                calendarEvent: calendarEvent),
                                          )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      headerChildBuilder: ({required bool displaySideBar}) =>
                          Container());
                });
          }),
    );
  }
}

class AttendancePollCard extends StatelessWidget {
  const AttendancePollCard(
      {Key? key,
      required this.calendarEvent,
      required this.room,
      required this.snapT})
      : super(key: key);

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
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CalendarEventWidget(p: p),
                    ],
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

class CalendarEventInfo extends StatelessWidget {
  const CalendarEventInfo(
      {Key? key,
      required this.room,
      required this.calendarEvent,
      required this.timeline})
      : super(key: key);

  final Room room;
  final Timeline timeline;
  final CalendarEvent calendarEvent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const H2Title("Info"),
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
              ListTile(
                leading: const Icon(Icons.people),
                title: Text("${room.summary.mJoinedMemberCount} participants"),
              ),
              if (room.canSendDefaultStates || calendarEvent.place != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const H2Title("Location"),
                    ListTile(
                      title: Text(calendarEvent.place != null
                          ? calendarEvent.place!
                          : "Set place"),
                      leading: const Icon(Icons.location_on),
                    ),
                  ],
                ),
              const H2Title("Date and time"),
              if (calendarEvent.start != null)
                DateTimeTile(text: "Start", date: calendarEvent.start!),
              if (calendarEvent.end != null && calendarEvent.start != null)
                calendarEvent.end!
                        .difference(
                            calendarEvent.start!.add(const Duration(days: 1)))
                        .isNegative
                    ? DurationWidget(calendarEvent: calendarEvent)
                    : DateTimeTile(text: "End", date: calendarEvent.end!),
              const H2Title("Organized by"),
              MatrixUserItem.fromUser(room.creator!, client: room.client),
              const SizedBox(height: 20),
            ],
          ),
        ),
        const H2Title("Images"),
        SocialGalleryPreviewWigdet(room: room, timeline: timeline),
      ],
    );
  }
}
