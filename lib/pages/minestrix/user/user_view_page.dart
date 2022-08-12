import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/layouts/layout_view.dart';
import 'package:minestrix/partials/post/post.dart';
import 'package:minestrix/partials/post/post_writer_modal.dart';
import 'package:minestrix/partials/users/user_friends_card.dart';
import 'package:minestrix/partials/users/user_profile_selection.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/chat/settings/conv_settings_card.dart';
import 'package:minestrix_chat/partials/custom_list_view.dart';
import 'package:minestrix_chat/partials/matrix/matrix_user_item.dart';
import 'package:minestrix_chat/partials/social/social_gallery_preview_widget.dart';
import 'package:minestrix_chat/partials/stories/stories_list.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/utils/spaces/space_extension.dart';

import '../../../partials/components/layouts/customHeader.dart';
import '../../../partials/components/minesTrix/MinesTrixTitle.dart';
import '../../../partials/minestrix_title.dart';
import '../../../partials/users/user_avatar.dart';
import '../../../router.gr.dart';
import 'follow_button.dart';
import 'message_button.dart';

/// This page display the base user information and the first MinesTRIX profile it could find
/// In case of multpile MinesTRIX profiles associated with this user, it should display
/// a way to select which one to display
class UserViewPage extends StatefulWidget {
  final String? userID;
  final Room? mroom;
  const UserViewPage({Key? key, this.userID, this.mroom})
      : assert(userID == null || mroom == null),
        assert(!(userID == null && mroom == null)),
        super(key: key);

  @override
  _UserViewPageState createState() => _UserViewPageState();
}

class _UserViewPageState extends State<UserViewPage> {
  ScrollController _controller = new ScrollController();

  String? _userId;

  RoomWithSpace? mroom;

  // getter
  String? get userId => mroom?.creatorId ?? _userId;

  // status
  bool _requestingHistory = false;

  Timeline? timeline;
  Future<Timeline?> getTimeline() async {
    if (timeline != null && timeline?.room == mroom?.room) return timeline!;

    final t = await mroom?.room?.getTimeline();

    if (t == null) return null;

    while (getEvents(t).length < 3 && t.canRequestHistory) {
      await t.requestHistory();
    }
    timeline = t;
    return t;
  }

  void setRoom(Room? room) {
    if (room != null) {
      mroom = RoomWithSpace(room: room);
    } else {
      mroom = null;
    }
  }

  void init() {
    final client = Matrix.of(context).client;

    if (mroom == null &&
        userId != null &&
        client.sroomsByUserId[userId!]?.isNotEmpty == true) {
      setRoom(client.sroomsByUserId[userId!]?.first);
    }

    // fallback
    if (userId == null &&
        mroom == null &&
        client.minestrixUserRoom.isNotEmpty) {
      setRoom(client.minestrixUserRoom.first);
    }

    if (userId == null) {
      _userId = client.userID;
    }
  }

  void updateIfWidgetArgumentChanged() {
    final updated =
        widget.userID != _prevUserId || widget.mroom?.id != _prevRoomId;

    if (updated) {
      resetView();
      setVariable();
      init();
    }
  }

  String? _prevRoomId;
  String? _prevUserId;

  void setVariable() {
    _prevRoomId = widget.mroom?.id;
    _prevUserId = widget.userID;

    _controller.addListener(scrollListener);
    if (mroom == null) setRoom(widget.mroom);
    _userId ??= widget.userID;
  }

  @override
  void initState() {
    super.initState();

    setVariable();

    init();
  }

  /// Reset the local variable when we changed the view
  void resetView() {
    mroom = null;
    _userId = null;
  }

  @override
  void deactivate() {
    super.deactivate();
    _controller.removeListener(scrollListener);
  }

  void scrollListener() async {
    if (_controller.position.pixels >=
        _controller.position.maxScrollExtent * 0.8) {
      if (_requestingHistory == false) {
        setState(() {
          _requestingHistory = true;
        });
        await timeline?.requestHistory();
        setState(() {
          _requestingHistory = false;
        });
      }
    }
  }

  void selectRoom(RoomWithSpace? r) {
    if (mroom == r) return;
    timeline = null;
    mroom = r;
    setState(() {});
  }

  List<Event> getEvents(Timeline timeline) =>
      timeline.room.client.getSRoomFilteredEvents(timeline, eventTypesFilter: [
        MatrixTypes.post,
        EventTypes.Encrypted,
        EventTypes.RoomCreate
      ]).toList();

  Widget headerChildBuilder({required bool displaySideBar, Profile? profile}) {
    final u = mroom?.room?.creator;
    final p = (u != null
        ? Profile(
            userId: u.id, displayName: u.displayName, avatarUrl: u.avatarUrl)
        : (profile ?? Profile(userId: 'fake user')));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
      child: Align(
          alignment:
              !displaySideBar ? Alignment.bottomCenter : Alignment.centerLeft,
          child: UserAvatar(p: p)),
    );
  }

  @override
  Widget build(BuildContext context) {
    updateIfWidgetArgumentChanged();

    final client = Matrix.of(context).client;

    return StreamBuilder<SyncUpdate>(
        stream: client.onSync.stream.where((up) => up.hasRoomUpdate),
        builder: (context, up) {
          // Discard the room if we left it.
          if (mroom != null &&
              up.data?.rooms?.leave?.containsKey(mroom!.id) == true) {
            mroom = null;
            timeline = null;
          }

          if (mroom == null) init();

          return FutureBuilder<Timeline?>(
              future: getTimeline(),
              builder: (context, snapshot) {
                Timeline? timeline = snapshot.data;

                List<Event> events =
                    timeline != null ? getEvents(timeline) : [];
                bool canRequestHistory = timeline?.canRequestHistory == true;
                bool isUserPage = userId == client.userID;

                return FutureBuilder<Profile>(
                    future: userId != null
                        ? client.getProfileFromUserId(userId!)
                        : null,
                    builder: (context, snapProfile) {
                      return LayoutBuilder(builder: (context, constraints) {
                        return LayoutView(
                          controller: _controller,
                          displayChat: false,
                          room: mroom?.room,
                          sidebarBuilder: () => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (userId != null)
                                UserProfileSelection(
                                    userId: userId!,
                                    onRoomSelected: selectRoom,
                                    roomSelectedId: mroom?.id),
                              if (mroom?.room != null)
                                Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: UserFriendsCard(room: mroom!.room!)),
                              if (timeline != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const H2Title("Images"),
                                    SocialGalleryPreviewWigdet(
                                        room: mroom!.room!, timeline: timeline),
                                  ],
                                ),
                            ],
                          ),
                          customHeader: CustomHeader(
                              title: isUserPage ? null : "User Feed",
                              actionButton: [
                                if (isUserPage)
                                  IconButton(
                                      icon: const Icon(Icons.settings),
                                      onPressed: () {
                                        context
                                            .navigateTo(const SettingsRoute());
                                      }),
                              ],
                              child: isUserPage
                                  ? FutureBuilder<Profile>(
                                      future: client.fetchOwnProfile(),
                                      builder: (context, snap) {
                                        return MatrixUserItem(
                                          name: snap.data?.displayName,
                                          userId: client.userID!,
                                          avatarUrl: snap.data?.avatarUrl,
                                          client: client,
                                        );
                                      })
                                  : null),
                          headerChildBuilder: (
                                  {required bool displaySideBar}) =>
                              headerChildBuilder(
                                  displaySideBar: displaySideBar,
                                  profile: snapProfile.data),
                          mainBuilder: ({required bool displaySideBar}) => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 680),
                                  child: CustomListViewWithEmoji(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      key: Key(mroom?.id ?? "room"),
                                      itemCount: events.length +
                                          2 +
                                          (canRequestHistory ? 1 : 0),
                                      itemBuilder: (context,
                                          i,
                                          void Function(Offset, Event)
                                              onReact) {
                                        if (i == 0) {
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 16.0,
                                                        horizontal: 8),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                        child: constraints
                                                                        .maxWidth <=
                                                                    900 &&
                                                                userId != null
                                                            ? UserProfileSelection(
                                                                userId: userId!,
                                                                dense: true,
                                                                onRoomSelected:
                                                                    selectRoom,
                                                                roomSelectedId:
                                                                    mroom?.id)
                                                            : Text(
                                                                mroom?.displayname ??
                                                                    '',
                                                                maxLines: 1,
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        24,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600))),
                                                    mroom?.creatorId ==
                                                            client.userID
                                                        ? IconButton(
                                                            icon: const Icon(
                                                                Icons.edit),
                                                            onPressed: () =>
                                                                ConvSettingsCard.show(
                                                                    context:
                                                                        context,
                                                                    room: mroom!
                                                                        .room!))
                                                        : Row(
                                                            children: [
                                                              if (mroom != null)
                                                                FollowingIndicator(
                                                                  room: mroom!,
                                                                ),
                                                              if (userId !=
                                                                      null &&
                                                                  userId !=
                                                                      client
                                                                          .userID)
                                                                MessageButton(
                                                                    userId:
                                                                        userId!)
                                                            ],
                                                          )
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        }

                                        if (timeline != null) {
                                          if (i == 1) {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (mroom != null &&
                                                    mroom?.topic != "")
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 8,
                                                            bottom: 24.0),
                                                    child: Text(mroom!.topic),
                                                  ),
                                                StoriesList(
                                                    client: client,
                                                    restrict: mroom?.creatorId,
                                                    allowCreatingStory:
                                                        mroom?.creatorId ==
                                                            client.userID),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: PostWriterModal(
                                                      room: mroom?.room),
                                                )
                                              ],
                                            );
                                          } else if ((i - 2) < events.length) {
                                            return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 2,
                                                        horizontal: 12),
                                                child: Post(
                                                    key: Key(
                                                        events[i - 2].eventId),
                                                    event: events[i - 2],
                                                    onReact: (Offset e) =>
                                                        onReact(
                                                            e, events[i - 2])));
                                          }

                                          return Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: MaterialButton(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      if (_requestingHistory)
                                                        const Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  right: 10),
                                                          child:
                                                              CircularProgressIndicator(),
                                                        ),
                                                      const Text(
                                                          "Load more posts"),
                                                    ],
                                                  ),
                                                ),
                                                onPressed: () async {
                                                  if (_requestingHistory ==
                                                      false) {
                                                    setState(() {
                                                      _requestingHistory = true;
                                                    });
                                                    await mroom?.room
                                                        ?.requestHistory();
                                                    setState(() {
                                                      _requestingHistory =
                                                          false;
                                                    });
                                                  }
                                                }),
                                          );
                                        } else if (mroom != null) {
                                          return const MinestrixTitle();
                                          // Room
                                        } else {
                                          return const MinestrixTitle();
                                        }
                                      }),
                                ),
                              ),
                            ],
                          ),
                        );
                      });
                    });
              });
        });
  }
}
