import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/account/contact_view.dart';
import 'package:minestrix/partials/components/buttons/custom_future_button.dart';
import 'package:minestrix/partials/components/minestrix/minestrix_title.dart';
import 'package:minestrix/partials/post/post.dart';
import 'package:minestrix/partials/post/post_writer_modal.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/pages/room_page.dart';
import 'package:minestrix_chat/partials/chat/user/selector/user_selector_dialog.dart';
import 'package:minestrix_chat/partials/custom_list_view.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/partials/social/social_gallery_preview_widget.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../../../partials/components/account/account_card.dart';
import '../../../partials/components/layouts/layout_view.dart';
import '../../../partials/feed/topic_list_tile.dart';

@RoutePage()
class GroupPage extends StatefulWidget {
  const GroupPage({Key? key, @pathParam required this.roomId})
      : super(key: key);
  final String roomId;

  @override
  GroupPageState createState() => GroupPageState();
}

class GroupPageState extends State<GroupPage> {
  late Future<Timeline> futureTimeline;

  final controller = ScrollController();
  bool updating = false;
  List<User> participants = [];

  late Room room;

  @override
  void initState() {
    room = Matrix.of(context).client.getRoomById(widget.roomId)!;
    futureTimeline = room.getTimeline();
    controller.addListener(scrollListener);

    super.initState();
  }

  void scrollListener() async {
    if (controller.position.pixels >=
        controller.position.maxScrollExtent - 600) {
      final timeline = await futureTimeline;

      if (timeline.canRequestHistory) {
        setState(() {
          updating = true;
        });

        await timeline.requestHistory();
        setState(() {
          updating = false;
        });
      }
    }
  }

  void inviteUsers() async {
    List<String>? userIds = await MinesTrixUserSelection.show(context, room);

    userIds?.forEach((String userId) async {
      await room.invite(userId);
    });
    participants = await room.requestParticipants();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Client sclient = Matrix.of(context).client;

    participants = room.getParticipants();
    return FutureBuilder<Timeline>(
        future: futureTimeline,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          Timeline timeline = snapshot.data!;
          List<Event> sevents = sclient.getSRoomFilteredEvents(timeline,
              eventTypesFilter: [
                MatrixTypes.post,
                EventTypes.Encrypted,
                EventTypes.RoomCreate
              ]).toList();

          return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            bool displayChatView = constraints.maxWidth > 1400;
            return LayoutView(
              controller: controller,
              customHeaderText: room.name,
              customHeaderActionsButtons: [
                IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      context.pushRoute(SocialSettingsRoute(room: room));
                    }),
              ],
              headerHeight: 300,
              room: room,
              mainBuilder: (
                      {required bool displaySideBar,
                      required bool displayLeftBar}) =>
                  StreamBuilder(
                      stream: room.onUpdate.stream,
                      builder: (context, _) => CustomListViewWithEmoji(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sevents.length + 1 + (updating ? 1 : 0),
                          itemBuilder: (BuildContext c, int i,
                              void Function(Offset, Event) onReact) {
                            if (i == 0) {
                              return Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: PostWriterModal(room: room),
                              );
                            }
                            return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 12),
                                child: (i - 1 < sevents.length)
                                    ? Post(
                                        event: sevents[i - 1],
                                        onReact: (e) =>
                                            onReact(e, sevents[i - 1]))
                                    : const PostShimmer());
                          })),
              sidebarBuilder: ({required bool displayLeftBar}) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder(
                      stream: sclient.onSync.stream,
                      builder: (context, _) => FutureBuilder<List<User>>(
                          future: room.requestParticipants(),
                          builder: (context, snap) {
                            if (snap.hasData == false) {
                              return const CircularProgressIndicator();
                            }

                            participants = snap.data!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const H2Title("About"),
                                    if (room.canSendDefaultStates ||
                                        room.topic.isNotEmpty)
                                      TopicListTile(room: room),
                                    ListTile(
                                        leading:
                                            room.joinRules == JoinRules.public
                                                ? const Icon(Icons.public)
                                                : const Icon(Icons.lock),
                                        title: Text(
                                            room.joinRules == JoinRules.public
                                                ? "Public group"
                                                : "Private group")),
                                    if (room.encrypted)
                                      const ListTile(
                                          leading:
                                              Icon(Icons.enhanced_encryption),
                                          title: Text("Encryption enabled")),
                                    ListTile(
                                      leading: const Icon(Icons.people),
                                      title: Text(
                                          "${room.summary.mJoinedMemberCount} members"),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Expanded(child: H2Title("Members")),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: IconButton(
                                          onPressed: inviteUsers,
                                          icon: const Icon(Icons.add)),
                                    )
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Wrap(
                                    children: [
                                      for (User p in participants.where(
                                          (User u) =>
                                              u.membership == Membership.join))
                                        AccountCard(user: p),
                                    ],
                                  ),
                                ),
                                if (participants.indexWhere((User u) =>
                                        u.membership == Membership.invite) !=
                                    -1)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const H2Title("Invited"),
                                      for (User p in participants.where(
                                          (User u) =>
                                              u.membership ==
                                              Membership.invite))
                                        ContactView(user: p),
                                    ],
                                  ),
                              ],
                            );
                          })),
                  if (!displayChatView)
                    CustomFutureButton(
                        icon: Icon(Icons.chat,
                            color: Theme.of(context).colorScheme.onPrimary),
                        color: Theme.of(context).colorScheme.primary,
                        children: [
                          Text("Open chat",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary)),
                          if (room.lastEvent?.text != null)
                            Text(room.lastEvent!.text,
                                maxLines: 2,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary)),
                        ],
                        onPressed: () async {
                          AdaptativeDialogs.show(
                              context: context,
                              title: "Group",
                              builder: (context) => RoomPage(
                                  roomId: widget.roomId, client: sclient));
                        }),
                  const H2Title("Images"),
                  SocialGalleryPreviewWigdet(room: room, timeline: timeline),
                ],
              ),
            );
          });
        });
  }
}
