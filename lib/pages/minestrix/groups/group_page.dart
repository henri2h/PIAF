import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/account/MinesTrixContactView.dart';
import 'package:minestrix/partials/components/buttons/custom_future_button.dart';
import 'package:minestrix/partials/components/layouts/custom_header.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/partials/post/post.dart';
import 'package:minestrix/partials/post/post_writer_modal.dart';
import 'package:minestrix/partials/users/MinesTrixUserSelection.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/chat/settings/conv_settings_card.dart';
import 'package:minestrix_chat/partials/custom_list_view.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/partials/social/social_gallery_preview_widget.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/view/room_page.dart';

import '../../../partials/components/account/account_card.dart';
import '../../../partials/components/layouts/layout_view.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({Key? key, required this.room}) : super(key: key);
  final Room room;

  @override
  GroupPageState createState() => GroupPageState();
}

class GroupPageState extends State<GroupPage> {
  late Future<Timeline> futureTimeline;

  final controller = ScrollController();
  bool updating = false;

  @override
  void initState() {
    futureTimeline = widget.room.getTimeline();
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

  @override
  Widget build(BuildContext context) {
    Client sclient = Matrix.of(context).client;
    Room room = widget.room;

    List<User> participants = room.getParticipants();
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
              customHeader: CustomHeader(
                title: room.name,
                actionButton: [
                  IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        ConvSettingsCard.show(context: context, room: room);
                      })
                ],
              ),
              headerHeight: 300,
              room: room,
              headerChildBuilder: ({required bool displaySideBar}) =>
                  Container(),
              mainBuilder: ({required bool displaySideBar}) => StreamBuilder(
                  stream: room.onUpdate.stream,
                  builder: (context, _) => CustomListViewWithEmoji(
                      itemCount: sevents.length + 1 + (updating ? 1 : 0),
                      itemBuilder: (BuildContext c, int i,
                          void Function(Offset, Event) onReact) {
                        if (i == 0) {
                          return Column(children: [
                            if (room.avatar != null)
                              Center(
                                  child: MatrixImageAvatar(
                                      client: sclient,
                                      url: room.avatar,
                                      unconstraigned: true,
                                      shape: MatrixImageAvatarShape.none,
                                      maxHeight: 500)),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: PostWriterModal(room: room),
                            ),
                          ]);
                        }
                        return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 2, horizontal: 12),
                            child: (i - 1 < sevents.length)
                                ? Post(
                                    event: sevents[i - 1],
                                    onReact: (e) => onReact(e, sevents[i - 1]))
                                : const PostShimmer());
                      })),
              sidebarBuilder: () => Column(
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
                                    if (room.topic.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(room.topic),
                                      ),
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
                                const H2Title("Members"),
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
                                        MinesTrixContactView(user: p),
                                    ],
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: MaterialButton(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      color: Theme.of(context).cardColor,
                                      child: const ListTile(
                                          title: Text("Add users"),
                                          leading: Icon(Icons.person_add)),
                                      onPressed: () async {
                                        List<Profile>? profiles =
                                            await AdaptativeDialogs.show(
                                                context: context,
                                                builder: (a) =>
                                                    MinesTrixUserSelection());

                                        profiles?.forEach((Profile p) async {
                                          await room.invite(p.userId);
                                        });
                                        participants =
                                            await room.requestParticipants();
                                        setState(() {});
                                      }),
                                ),
                              ],
                            );
                          })),
                  if (!displayChatView)
                    CustomFutureButton(
                        icon: Icon(Icons.chat,
                            color: Theme.of(context).colorScheme.onPrimary),
                        color: Theme.of(context).primaryColor,
                        children: [
                          Text("Open chat",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary)),
                          if (widget.room.lastEvent?.text != null)
                            Text(widget.room.lastEvent!.text,
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
                                  roomId: widget.room.id, client: sclient));
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
