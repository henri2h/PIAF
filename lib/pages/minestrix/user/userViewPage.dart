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
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/custom_list_view.dart';
import 'package:minestrix_chat/partials/stories/stories_list.dart';
import 'package:minestrix_chat/utils/profile_space.dart';
import 'package:minestrix_chat/utils/spaces/space_extension.dart';
import 'package:minestrix_chat/view/matrix_chat_page.dart';
import 'package:minestrix_chat/view/matrix_chats_page.dart';

import '../../../partials/components/buttons/customFutureButton.dart';

/// This page display the base user information and the first MinesTRIX profile it could find
/// In case of multpile MinesTRIX profiles associated with this user, it should display
/// a way to select which one to display
class UserViewPage extends StatefulWidget {
  final String? userID;
  final MinestrixRoom? mroom;
  const UserViewPage({Key? key, this.userID, this.mroom})
      : assert(userID == null || mroom == null),
        super(key: key);

  @override
  _UserViewPageState createState() => _UserViewPageState();
}

class _UserViewPageState extends State<UserViewPage> {
  MinestrixRoom? mroom;

  String? userId;
  bool _requestingHistory = false;

  ScrollController _controller = new ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(scrollListener);
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
        await mroom?.timeline?.requestHistory();
        setState(() {
          _requestingHistory = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // if we navigate to an other user
    if (userId != (widget.userID ?? widget.mroom?.userID)) {
      userId = null;
      mroom = null;
    }

    MinestrixClient sclient = Matrix.of(context).sclient!;
    mroom ??= widget.mroom;

    if (mroom == null) {
      userId = widget.userID;
      userId ??= sclient.userID;

      String? roomId = sclient.userIdToRoomId[userId!];
      if (roomId != null) mroom = sclient.srooms[roomId];
    } else {
      userId = mroom!.userID;
    }

    User? user_in = sclient.userRoom?.room.getParticipants().firstWhereOrNull(
        (User u) => (u.id == userId)); // check if the user is following us

    return FutureBuilder<Profile>(
        future: sclient.getProfileFromUserId(userId!),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData == false) {
            return CircularProgressIndicator();
          }
          Profile p = snapshot.data;
          p.userId = userId!; // fix a nasty bug :(

          List<Event>? timeline;
          if (mroom?.timeline != null)
            timeline =
                sclient.getSRoomFilteredEvents(mroom!.timeline!).toList();

          bool canRequestHistory = mroom?.timeline?.canRequestHistory == true;
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
                                onRoomSelected: (MinestrixRoom r) {
                                  setState(() {
                                    mroom = r;
                                  });
                                },
                                roomSelectedId: mroom?.room.id),
                            Padding(
                                padding: const EdgeInsets.all(15),
                                child: UserFriendsCard(sroom: mroom!)),
                          ],
                        ),
                      ),
                    Flexible(
                      child: CustomListViewWithEmoji(
                          key: Key(mroom?.room.id ?? "room"),
                          controller: _controller,
                          itemCount: timeline?.length != null
                              ? timeline!.length +
                                  2 +
                                  (canRequestHistory ? 1 : 0)
                              : 2,
                          itemBuilder: (context, i,
                              void Function(Offset, Event) onReact) {
                            if (i == 0)
                              return Column(
                                children: [
                                  UserInfo(profile: p, room: mroom?.room),
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
                                        client: sclient,
                                        restrict: mroom!.userID),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: PostWriterModal(sroom: mroom),
                                    )
                                  ],
                                );
                              } else if ((i - 2) < timeline.length) {
                                return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 2, horizontal: 12),
                                    child: Post(
                                        event: timeline[i - 2],
                                        onReact: (Offset e) =>
                                            onReact(e, timeline![i - 2])));
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
                                        await mroom!.room.requestHistory();
                                        setState(() {
                                          _requestingHistory = false;
                                        });
                                      }
                                    }),
                              );
                            } else {
                              return UnknownUser(
                                  user_in: user_in, sclient: sclient, p: p);
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
  final MinestrixClient sclient;
  final Profile p;
  const UnknownUser(
      {Key? key, required this.user_in, required this.sclient, required this.p})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Row(
            children: [
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
              Flexible(
                child: MinesTrixButton(
                    icon: Icons.message,
                    label: "Send message",
                    onPressed: () {
                      String? roomId =
                          sclient.getDirectChatFromUserId(p.userId);
                      if (roomId != null) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    MatrixChatPage(
                                        roomId: roomId, client: sclient)));
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) => Scaffold(
                                    appBar: AppBar(title: Text("Start chat")),
                                    body: MatrixChatsPage(client: sclient))));
                      }
                    }),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 100),
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
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: FutureBuilder<List<SpaceRoom>?>(
              future: getProfileSpaceContent(),
              builder: (context, snapshot) {
                List<SpaceRoom> profiles = (snapshot.data ?? [])
                    .where((SpaceRoom room) =>
                        room.roomType == MatrixTypes.account)
                    .toList();

                if (!snapshot.hasData) return CircularProgressIndicator();
                return Column(
                  children: [
                    for (SpaceRoom space in profiles)
                      if ([JoinRules.knock, JoinRules.public]
                              .contains(space.joinRule) &&
                          (sclient.getRoomById(space.id) == null ||
                              ![Membership.knock, Membership.join].contains(
                                  sclient.getRoomById(space.id)?.membership)))
                        CustomFutureButton(
                            icon: Icon(Icons.person_add),
                            children: [
                              Text(space.name),
                              Text("Follow",
                                  style: TextStyle(fontWeight: FontWeight.bold))
                            ],
                            onPressed: () async {},
                            expanded: false),
                  ],
                );
              }),
        )
      ],
    );
  }

  Future<List<SpaceRoom>?> getProfileSpaceContent() async {
    var roomId =
        await sclient.getRoomIdByAlias(ProfileSpace.getAliasName(p.userId));
    if (roomId.roomId == null) return null;
    return await sclient.getRoomHierarchy(roomId.roomId!);
  }
}
