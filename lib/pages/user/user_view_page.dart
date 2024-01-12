import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/layouts/layout_view.dart';
import 'package:minestrix/partials/post/post_writer_modal.dart';
import 'package:minestrix/partials/user/user_friends_card.dart';
import 'package:minestrix/partials/user/user_profile_selection.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix/chat/config/matrix_types.dart';
import 'package:minestrix/chat/minestrix_chat.dart';
import 'package:minestrix/chat/partials/custom_list_view.dart';
import 'package:minestrix/chat/partials/feed/minestrix_room_tile.dart';
import 'package:minestrix/chat/partials/social/social_gallery_preview_widget.dart';
import 'package:minestrix/chat/partials/stories/stories_list.dart';
import 'package:minestrix/chat/utils/matrix_widget.dart';
import 'package:minestrix/chat/utils/spaces/space_extension.dart';

import '../../partials/components/minestrix/minestrix_title.dart';
import '../../partials/feed/topic_list_tile.dart';
import '../../partials/minestrix_title.dart';
import '../../partials/post/post.dart';
import '../../partials/post/post_shimmer.dart';
import '../../partials/user/user_avatar.dart';
import '../../router.gr.dart';
import '../../partials/user/follow_button.dart';
import '../../partials/user/message_button.dart';

/// This page display the base user information and the first MinesTRIX profile it could find
/// In case of multpile MinesTRIX profiles associated with this user, it should display
/// a way to select which one to display

@RoutePage()
class UserViewPage extends StatefulWidget {
  final String? userID;
  final Room? mroom;
  const UserViewPage({super.key, this.userID, this.mroom})
      : assert(userID == null || mroom == null),
        assert(!(userID == null && mroom == null));

  @override
  UserViewPageState createState() => UserViewPageState();
}

class UserViewPageState extends State<UserViewPage>
    with TickerProviderStateMixin {
  ScrollController controller = ScrollController();

  late TabController _tabController;
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

    controller = ScrollController();

    controller.addListener(scrollListener);
    if (mroom == null) setRoom(widget.mroom);
    _userId ??= widget.userID;
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

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
    controller.removeListener(scrollListener);
  }

  void scrollListener() async {
    if (controller.positions.length == 1 &&
        controller.position.pixels >=
            controller.position.maxScrollExtent - 600) {
      if (_requestingHistory == false && timeline?.canRequestHistory == true) {
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

  void displaySelectRoomModal() async {
    final client = Matrix.of(context).client;

    await showModalBottomSheet(
        context: context,
        useSafeArea: true,
        builder: (context) {
          final rooms = client.sroomsByUserId[userId!]?.toList() ?? [];

          return FutureBuilder<List<SpaceRoomsChunk>?>(
              future: client.getProfileSpaceHierarchy(userId!),
              builder: (context, snap) {
                final results =
                    rooms.map((e) => RoomWithSpace(room: e)).toList();
                final discoveredRooms = snap.data;

                discoveredRooms?.forEach((space) {
                  final res = results.firstWhereOrNull(
                      (item) => item.room?.id == space.roomId);
                  if (res != null) {
                    res.space = space;
                  } else {
                    if (space.roomType == MatrixTypes.account) {
                      results.add(RoomWithSpace(space: space, creator: userId));
                    }
                  }
                });

                return Column(children: [
                  for (final room in rooms)
                    RadioListTile(
                      value: room,
                      groupValue: mroom?.room,
                      onChanged: (Room? val) {
                        if (val != null) {
                          selectRoom(RoomWithSpace(room: val));

                          Navigator.of(context).pop();
                        }
                      },
                      title: MinestrixRoomTile(
                        room: room,
                        onTap: () {
                          selectRoom(RoomWithSpace(room: room));

                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                ]);
              });
        });
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
                          controller: controller,
                          displayChat: false,
                          room: mroom?.room,
                          leftBar: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (userId != null)
                                UserProfileSelection(
                                    userId: userId!,
                                    onRoomSelected: selectRoom,
                                    roomSelectedId: mroom?.id),
                            ],
                          ),
                          sidebarBuilder: ({required bool displayLeftBar}) =>
                              Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!displayLeftBar)
                                UserProfileSelection(
                                    userId: userId!,
                                    onRoomSelected: selectRoom,
                                    roomSelectedId: mroom?.id),
                              const SizedBox(
                                height: 8,
                              ),
                              if (mroom?.room != null)
                                Card(
                                  elevation: 3,
                                  child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child:
                                          UserFriendsCard(room: mroom!.room!)),
                                ),
                            ],
                          ),
                          customHeaderText:
                              isUserPage ? "My feed" : "User Feed",
                          customHeaderActionsButtons: [
                            if (isUserPage)
                              IconButton(
                                  icon: const Icon(Icons.settings),
                                  onPressed: () {
                                    context.navigateTo(const SettingsRoute());
                                  }),
                            if (isUserPage)
                              IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    final space = client.getProfileSpace();
                                    if (space != null) {
                                      context.pushRoute(
                                          SocialSettingsRoute(room: space));
                                    }
                                  }),
                            if (userId != null)
                              IconButton(
                                  icon: const Icon(Icons.list),
                                  onPressed: displaySelectRoomModal)
                          ],
                          headerChildBuilder: (
                                  {required bool displaySideBar}) =>
                              headerChildBuilder(
                                  displaySideBar: displaySideBar,
                                  profile: snapProfile.data),
                          mainBuilder: (
                                  {required bool displaySideBar,
                                  required bool displayLeftBar}) =>
                              Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 680),
                                  child: Column(
                                    children: [
                                      Card(
                                        child: Column(
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
                                                      child: Text(
                                                          mroom?.displayname ??
                                                              '',
                                                          maxLines: 1,
                                                          style: const TextStyle(
                                                              fontSize: 24,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600))),
                                                  if (mroom?.creatorId ==
                                                      client.userID)
                                                    IconButton(
                                                        icon: const Icon(
                                                            Icons.edit),
                                                        onPressed: () {
                                                          context.pushRoute(
                                                              SocialSettingsRoute(
                                                                  room: mroom!
                                                                      .room!));
                                                        }),
                                                  Row(
                                                    children: [
                                                      if (mroom != null)
                                                        FollowingIndicator(
                                                          room: mroom!,
                                                          onUnfollow: () {
                                                            setState(() {
                                                              _userId = mroom
                                                                  ?.creatorId;
                                                              mroom = null;
                                                            });
                                                          },
                                                        ),
                                                      if (userId != null &&
                                                          userId !=
                                                              client.userID)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 4.0),
                                                          child: MessageButton(
                                                              userId: userId!),
                                                        )
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                            if (mroom?.room == null &&
                                                mroom?.topic.isNotEmpty == true)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 4,
                                                        horizontal: 8.0),
                                                child: Text(mroom!.topic),
                                              ),
                                            if (mroom?.room != null)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(18.0),
                                                child: TopicListTile(
                                                    room: mroom!.room!),
                                              ),
                                            TabBar(
                                                controller: _tabController,
                                                onTap: (val) {
                                                  setState(() {});
                                                },
                                                tabs: const [
                                                  Tab(text: "Feed"),
                                                  Tab(text: "Followers"),
                                                  Tab(text: "Images"),
                                                ]),
                                          ],
                                        ),
                                      ),
                                      Builder(builder: (context) {
                                        if (_tabController.index == 1 &&
                                            timeline != null) {
                                          final room = timeline.room;

                                          return UserFriendsCard(room: room);
                                        } else if (_tabController.index == 2 &&
                                            timeline != null) {
                                          return ImagesTab(
                                              mroom: mroom, timeline: timeline);
                                        }
                                        return CustomListViewWithEmoji(
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            key: Key(mroom?.id ?? "room"),
                                            itemCount: events.length +
                                                1 +
                                                (canRequestHistory ? 1 : 0),
                                            itemBuilder: (context,
                                                i,
                                                void Function(Offset, Event)
                                                    onReact) {
                                              if (timeline != null) {
                                                if (i == 0) {
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      StoriesList(
                                                          client: client,
                                                          restrictUserID:
                                                              mroom?.creatorId,
                                                          allowCreatingStory:
                                                              mroom?.creatorId ==
                                                                  client
                                                                      .userID),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: PostWriterModal(
                                                            room: mroom?.room),
                                                      )
                                                    ],
                                                  );
                                                } else if ((i - 1) <
                                                    events.length) {
                                                  return Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 2,
                                                          horizontal: 12),
                                                      child: Builder(
                                                          builder: (context) {
                                                        final event =
                                                            events[i - 1];
                                                        return Post(
                                                            key: Key(
                                                                event.eventId),
                                                            event: event,
                                                            onReact:
                                                                (Offset e) =>
                                                                    onReact(e,
                                                                        event));
                                                      }));
                                                }

                                                return Column(
                                                  children: [
                                                    if (_requestingHistory)
                                                      const PostShimmer(),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: MaterialButton(
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                if (_requestingHistory)
                                                                  const Padding(
                                                                    padding: EdgeInsets.only(
                                                                        right:
                                                                            10),
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
                                                                _requestingHistory =
                                                                    true;
                                                              });
                                                              await mroom?.room
                                                                  ?.requestHistory();
                                                              setState(() {
                                                                _requestingHistory =
                                                                    false;
                                                              });
                                                            }
                                                          }),
                                                    ),
                                                  ],
                                                );
                                              } else if (mroom != null) {
                                                return const MinestrixTitle();
                                                // Room
                                              } else {
                                                return const MinestrixTitle();
                                              }
                                            });
                                      }),
                                    ],
                                  ),
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

class ImagesTab extends StatelessWidget {
  const ImagesTab({
    super.key,
    required this.mroom,
    required this.timeline,
  });

  final RoomWithSpace? mroom;
  final Timeline timeline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const H2Title("Images"),
        SocialGalleryPreviewWigdet(room: mroom!.room!, timeline: timeline),
      ],
    );
  }
}
