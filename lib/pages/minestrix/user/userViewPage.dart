import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/buttons/MinesTrixButton.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/partials/post/postView.dart';
import 'package:minestrix/partials/post/postWriterModal.dart';
import 'package:minestrix/partials/users/userFriendsCard.dart';
import 'package:minestrix/partials/users/userInfo.dart';
import 'package:minestrix/partials/users/userProfileSelection.dart';
import 'package:minestrix/utils/matrix_widget.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/custom_list_view.dart';
import 'package:minestrix_chat/partials/stories/stories_list.dart';
import 'package:minestrix_chat/utils/matrix/client_extension.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';
import 'package:minestrix_chat/utils/profile_space.dart';
import 'package:minestrix_chat/utils/spaces/space_extension.dart';
import 'package:minestrix_chat/view/matrix_chat_page.dart';
import 'package:minestrix_chat/view/matrix_chats_page.dart';

import '../../../partials/components/buttons/customFutureButton.dart';
import '../../../partials/feed/minestrixProfileNotCreated.dart';

/// This page display the base user information and the first MinesTRIX profile it could find
/// In case of multpile MinesTRIX profiles associated with this user, it should display
/// a way to select which one to display
class UserViewPage extends StatefulWidget {
  final String? userID;
  final Room? mroom;
  const UserViewPage({Key? key, this.userID, this.mroom})
      : assert(userID == null || mroom == null),
        super(key: key);

  @override
  _UserViewPageState createState() => _UserViewPageState();
}

class _UserViewPageState extends State<UserViewPage> {
  Room? mroom;

  String? userId;
  bool _requestingHistory = false;

  ScrollController _controller = new ScrollController();

  Future<Timeline>? futureTimeline;

  @override
  void initState() {
    super.initState();
    _controller.addListener(scrollListener);

    // if we navigate to an other user
    if (userId != (widget.userID ?? widget.mroom?.creatorId)) {
      userId = null;
      mroom = null;
    }

    mroom ??= widget.mroom;

    Client client = Matrix.of(context).client;

    if (mroom == null) {
      userId = widget.userID;
      userId ??= client.userID;

      //String? roomId = client.userIdToRoomId[userId!];
      //if (roomId != null) mroom = client.srooms[roomId];
      if (client.minestrixUserRoom.isNotEmpty)
        mroom = client.minestrixUserRoom.first;
    } else {
      userId = mroom!.creatorId;
    }

    futureTimeline = mroom?.getTimeline();
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
        print("[ userFeedPage ] : update from scroll");
        await (await futureTimeline)?.requestHistory();
        setState(() {
          _requestingHistory = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Client client = Matrix.of(context).client;

    // TODO: support for mulitple feeds
    User? user_in = client.minestrixUserRoom.firstOrNull
        ?.getParticipants()
        .firstWhereOrNull(
            (User u) => (u.id == userId)); // check if the user is following us

    return FutureBuilder<Timeline>(
        future: futureTimeline,
        builder: (context, snapshot) {
          Timeline? timeline = snapshot.data;

          List<Event> events = [];
          if (timeline != null)
            events = client.getSRoomFilteredEvents(timeline).toList();

          bool canRequestHistory = timeline?.canRequestHistory == true;

          return LayoutBuilder(builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1200),
                child: Row(
                  children: [
                    if (constraints.maxWidth > 900 && mroom != null)
                      SizedBox(
                        width: 300,
                        child: ListView(
                          children: [
                            UserProfileSelection(
                                userId: userId!,
                                onRoomSelected: (Room r) {
                                  setState(() {
                                    mroom = r;
                                  });
                                },
                                roomSelectedId: mroom?.id),
                            Padding(
                                padding: const EdgeInsets.all(15),
                                child: UserFriendsCard(room: mroom!)),
                          ],
                        ),
                      ),
                    Flexible(
                      child: CustomListViewWithEmoji(
                          key: Key(mroom?.id ?? "room"),
                          controller: _controller,
                          itemCount:
                              events.length + 2 + (canRequestHistory ? 1 : 0),
                          itemBuilder: (context, i,
                              void Function(Offset, Event) onReact) {
                            if (i == 0)
                              return Column(
                                children: [
                                  if (mroom != null) UserInfo(room: mroom),
                                  SizedBox(
                                    height: 20,
                                  ),
                                ],
                              );

                            if (timeline != null) {
                              if (i == 1) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 8.0),
                                        child: H2Title("Posts"),
                                      ),
                                    ),
                                    StoriesList(
                                        client: client,
                                        restrict: mroom?.creatorId,
                                        allowCreatingStory:
                                            mroom?.creatorId == client.userID),
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
                  ],
                ),
              ),
            );
          });
        });
  }
}

class UnknownUser extends StatelessWidget {
  final User? user_in;
  final Client client;
  final String? userId;
  const UnknownUser(
      {Key? key,
      required this.user_in,
      required this.client,
      required this.userId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FutureBuilder<List<SpaceRoom>?>(
                    future: getProfileSpaceContent(),
                    builder: (context, snapshot) {
                      List<SpaceRoom> profiles = (snapshot.data ?? [])
                          .where((SpaceRoom room) =>
                              room.roomType == MatrixTypes.account)
                          .toList();
// we ignore generated by getProfileSpaceContent when the space doesn't exist
                      return Column(
                        children: [
                          for (SpaceRoom space in profiles)
                            if ([JoinRules.knock, JoinRules.public]
                                    .contains(space.joinRule) &&
                                (client.getRoomById(space.id) == null ||
                                    ![Membership.knock, Membership.join]
                                        .contains(client
                                            .getRoomById(space.id)
                                            ?.membership)))
                              CustomFutureButton(
                                  icon: Icon(Icons.person_add,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary),
                                  color: Theme.of(context).primaryColor,
                                  children: [
                                    Text(space.name,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary)),
                                    Text("Follow",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary))
                                  ],
                                  onPressed: () async {
                                    switch (space.joinRule) {
                                      case JoinRules.public:
                                        client.joinRoom(space
                                            .id); // TODO: update me to support joining over federation (need the via field)
                                        await client
                                            .waitForRoomInSync(space.id);

                                        break;
                                      case JoinRules.knock:
                                        client.knockRoom(space.id);
                                        await client
                                            .waitForRoomInSync(space.id);

                                        break;
                                      default:
                                    }
                                    client.knockRoom(space.id);
                                  },
                                  expanded: false),
                        ],
                      );
                    }),
              ),
              if (user_in != null && user_in?.membership == Membership.invite)
                Flexible(
                    child: MinesTrixButton(
                  icon: Icons.send,
                  label: "Friend request sent",
                  onPressed: null,
                )),
              if (user_in != null && user_in?.membership == Membership.join)
                Flexible(
                    child: MinesTrixButton(
                  icon: Icons.person,
                  label: "Friend",
                  onPressed: null,
                )),
              SizedBox(width: 30),
              if (userId != client.userID)
                CustomFutureButton(
                    icon: Icon(Icons.message),
                    children: [Text("Send a message")],
                    expanded: false,
                    onPressed: () async {
                      if (userId == null) return;
                      String? roomId = client.getDirectChatFromUserId(userId!);
                      if (roomId != null) {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    MatrixChatPage(
                                        roomId: roomId,
                                        client: client,
                                        onBack: () => context.popRoute())));
                      } else {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) => Scaffold(
                                    appBar: AppBar(title: Text("Start chat")),
                                    body: MatrixChatsPage(client: client))));
                      }
                    }),
            ],
          ),
        ),
        userId != client.userID
            ? Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 60, vertical: 100),
                child: Column(
                  children: [
                    Text("Your are not in this user friend list",
                        style: TextStyle(fontSize: 40)),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text("😧", style: TextStyle(fontSize: 40)),
                    ),
                    Text(
                        "Or he/she may not have a MINESTRIX account (yet), send him a message ;)",
                        style: TextStyle(fontSize: 20))
                  ],
                ),
              )
            : MinestrixProfileNotCreated()
      ],
    );
  }

  Future<List<SpaceRoom>?> getProfileSpaceContent() async {
    if (userId != null) {
      var roomId =
          await client.getRoomIdByAlias(ProfileSpace.getAliasName(userId!));
      if (roomId.roomId == null) return null;
      return await client.getRoomHierarchy(roomId.roomId!);
    }
    return null;
  }
}
