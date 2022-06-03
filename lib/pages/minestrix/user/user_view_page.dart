import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/pages/minestrix/user/unknown_user.dart';
import 'package:minestrix/partials/post/post.dart';
import 'package:minestrix/partials/post/post_writer_modal.dart';
import 'package:minestrix/partials/users/userFriendsCard.dart';
import 'package:minestrix/partials/users/user_info.dart';
import 'package:minestrix/partials/users/user_profile_selection.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/chat/settings/conv_settings_card.dart';
import 'package:minestrix_chat/partials/custom_list_view.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/partials/stories/stories_list.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/view/room_list_page.dart';
import 'package:minestrix_chat/view/room_page.dart';

import '../../../partials/components/buttons/customFutureButton.dart';
import '../../../partials/components/layouts/customHeader.dart';
import '../../../router.gr.dart';

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
  late Client client;
  ScrollController _controller = new ScrollController();

  String? _userId;

  Room? mroom;

  // getter
  String? get userId => mroom?.creatorId ?? _userId;

  // status
  bool _requestingHistory = false;

  Timeline? timeline;
  Future<Timeline?> getTimeline() async {
    if (timeline != null && timeline?.room == mroom) return timeline!;
    final t = await mroom?.getTimeline();

    if (t == null) return null;

    while (getEvents(t).length < 3 && t.canRequestHistory) {
      await t.requestHistory();
    }
    timeline = t;
    return t;
  }

  void init() {
    mroom ??= widget.mroom;

    Client client = Matrix.of(context).client;

    if (mroom == null && userId != null) {
      mroom = client.sroomsByUserId[userId!]?.first;
    }

    // fallback
    if (userId == null && mroom == null && client.minestrixUserRoom.isNotEmpty)
      mroom = client.minestrixUserRoom.first;
  }

  @override
  void initState() {
    super.initState();

    _controller.addListener(scrollListener);

    client = Matrix.of(context).client;

    if (widget.userID != client.userID)
      _userId = widget
          .userID; // only store the userId if a different user than the one currently logged in. So if we want to change the currently logged user, we can change the user displayed.

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

  void selectRoom(Room r) {
    if (mroom == r) return;
    timeline = null;
    mroom = r;
    setState(() {});
  }

  List<Event> getEvents(Timeline timeline) =>
      client.getSRoomFilteredEvents(timeline, eventTypesFilter: [
        MatrixTypes.post,
        EventTypes.Encrypted,
        EventTypes.RoomCreate
      ]).toList();

  @override
  Widget build(BuildContext context) {
    Client client = Matrix.of(context).client;

    // TODO: support for mulitple feeds
    User? user_in = client.minestrixUserRoom.firstOrNull
        ?.getParticipants()
        .firstWhereOrNull(
            (User u) => (u.id == userId)); // check if the user is following us

    return FutureBuilder<Timeline?>(
        future: getTimeline(),
        builder: (context, snapshot) {
          Timeline? timeline = snapshot.data;

          List<Event> events = timeline != null ? getEvents(timeline) : [];
          bool canRequestHistory = timeline?.canRequestHistory == true;
          bool isUserPage = mroom?.creatorId == client.userID;

          return LayoutBuilder(builder: (context, constraints) {
            return ListView(
              controller: _controller,
              children: [
                CustomHeader(
                    child: isUserPage
                        ? ClientChooser(onUpdate: () {
                            resetView(); // we need to discard the previous data
                            init();

                            setState(() {});
                          })
                        : null,
                    title: isUserPage ? null : "User Feed",
                    actionButton: [
                      if (isUserPage)
                        IconButton(
                            icon: Icon(Icons.settings),
                            onPressed: () {
                              context.navigateTo(SettingsRoute());
                            }),
                    ]),
                if (mroom != null) UserInfo(room: mroom),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (constraints.maxWidth > 900 && mroom != null)
                      SizedBox(
                        width: 300,
                        child: Column(
                          children: [
                            UserProfileSelection(
                                userId: userId!,
                                onRoomSelected: selectRoom,
                                roomSelectedId: mroom?.id),
                            Padding(
                                padding: const EdgeInsets.all(15),
                                child: UserFriendsCard(room: mroom!)),
                          ],
                        ),
                      ),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 680),
                        child: CustomListViewWithEmoji(
                            key: Key(mroom?.id ?? "room"),
                            itemCount:
                                events.length + 2 + (canRequestHistory ? 1 : 0),
                            itemBuilder: (context, i,
                                void Function(Offset, Event) onReact) {
                              if (i == 0)
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                          child: Text(mroom?.displayname ?? '',
                                              maxLines: 1,
                                              style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight:
                                                      FontWeight.w600))),
                                      if (mroom != null)
                                        mroom!.creatorId == client.userID
                                            ? IconButton(
                                                icon: Icon(Icons.settings),
                                                onPressed: () =>
                                                    ConvSettingsCard.show(
                                                        context: context,
                                                        room: mroom!))
                                            : Row(
                                                children: [
                                                  FollowingIndicator(),
                                                  if (mroom!.creatorId != null)
                                                    MessageButton(
                                                        userId:
                                                            mroom!.creatorId!)
                                                ],
                                              )
                                    ],
                                  ),
                                );

                              if (timeline != null) {
                                if (i == 1) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (mroom?.topic != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 8, bottom: 24.0),
                                          child: Text(mroom!.topic),
                                        ),
                                      StoriesList(
                                          client: client,
                                          restrict: mroom?.creatorId,
                                          allowCreatingStory:
                                              mroom?.creatorId ==
                                                  client.userID),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: PostWriterModal(room: mroom),
                                      )
                                    ],
                                  );
                                } else if ((i - 2) < events.length) {
                                  return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2, horizontal: 12),
                                      child: Post(
                                          key: Key(events[i - 2].eventId),
                                          event: events[i - 2],
                                          onReact: (Offset e) =>
                                              onReact(e, events[i - 2])));
                                }

                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: MaterialButton(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (_requestingHistory)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 10),
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            Text("Load more posts"),
                                          ],
                                        ),
                                      ),
                                      onPressed: () async {
                                        if (_requestingHistory == false) {
                                          setState(() {
                                            _requestingHistory = true;
                                          });
                                          await mroom!.requestHistory();
                                          setState(() {
                                            _requestingHistory = false;
                                          });
                                        }
                                      }),
                                );
                              } else {
                                return UnknownUser(
                                    user_in: user_in,
                                    client: client,
                                    userId: userId);
                              }
                            }),
                      ),
                    ),
                  ],
                ),
              ],
            );
          });
        });
  }
}

class FollowingIndicator extends StatelessWidget {
  const FollowingIndicator({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomFutureButton(
        expanded: false,
        color: Theme.of(context).primaryColor,
        padding: EdgeInsets.all(6),
        icon:
            Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimary),
        onPressed: null,
        children: [
          Text("Following",
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary))
        ]);
  }
}

class MessageButton extends StatelessWidget {
  final String userId;
  const MessageButton({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    return CustomFutureButton(
        icon: Icon(Icons.message),
        children: [Text("Message")],
        padding: EdgeInsets.all(6),
        expanded: false,
        onPressed: () async {
          String? roomId = client.getDirectChatFromUserId(userId);
          await AdaptativeDialogs.show(
              context: context,
              builder: (BuildContext context) => roomId != null
                  ? RoomPage(
                      roomId: roomId,
                      client: client,
                      onBack: () => context.popRoute())
                  : RoomsListPage(client: client));
        });
  }
}
