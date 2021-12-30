import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/partials/users/userFeed.dart';
import 'package:minestrix/partials/users/userInfo.dart';
import 'package:minestrix/partials/users/userProfileSelection.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';
import 'package:minestrix_chat/view/matrix_chat_page.dart';
import 'package:minestrix_chat/view/matrix_chats_page.dart';

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
  bool _updating = false;

  bool requestingHistory = false;
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
      if (_updating == false) {
        setState(() {
          _updating = true;
        });
        print("[ userFeedPage ] : update from scroll");
        await mroom?.timeline?.requestHistory();
        setState(() {
          _updating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;
    mroom ??= widget.mroom;

    if (mroom == null) {
      userId = widget.userID;
      userId ??= sclient.userID;

      String? roomId = sclient.userIdToRoomId[userId!];
      if (roomId != null) mroom = sclient.srooms[roomId];
    } else {
      userId = mroom!.user.id;
    }

    User? user_in = sclient.userRoom!.room.getParticipants().firstWhereOrNull(
        (User u) => (u.id == userId)); // check if the user is following us

    return FutureBuilder<Profile>(
        future: sclient.getProfileFromUserId(userId!),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData == false) {
            return CircularProgressIndicator();
          }
          Profile p = snapshot.data;
          p.userId = userId!; // fix a nasty bug :(

          return ListView(controller: _controller, children: [
            UserInfo(profile: p, room: mroom?.room),
            SizedBox(
              height: 20,
            ),
            UserProfileSelection(
                userId: userId!,
                onRoomSelected: (MinestrixRoom r) {
                  setState(() {
                    mroom = r;
                  });
                },
                roomSelectedId: mroom?.room.id),
            mroom != null
                ? UserFeed(
                    sroom: mroom!,
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 20),
                        child: Row(
                          children: [
                            if (user_in == null ||
                                (user_in.membership != Membership.join &&
                                    user_in.membership != Membership.invite))
                              Flexible(
                                child: MinesTrixButton(
                                    icon: Icons.person_add,
                                    label: "Follow",
                                    onFuturePressed: () async {
                                      await sclient.addFriend(p.userId);
                                      setState(() {});
                                    }),
                              ),
                            if (user_in != null &&
                                user_in.membership == Membership.invite)
                              Flexible(
                                  child: MinesTrixButton(
                                icon: Icons.send,
                                label: "Friend request sent",
                                onPressed: null,
                              )),
                            if (user_in != null &&
                                user_in.membership == Membership.join)
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
                                    String? roomId = sclient
                                        .getDirectChatFromUserId(userId!);
                                    if (roomId != null) {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (BuildContext context) =>
                                                  MatrixChatPage(
                                                      roomId: roomId,
                                                      client: sclient)));
                                    } else {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (BuildContext context) =>
                                                  Scaffold(
                                                      appBar: AppBar(
                                                          title: Text(
                                                              "Start chat")),
                                                      body: MatrixChatsPage(
                                                          client: sclient))));
                                    }
                                  }),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 60, vertical: 100),
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
                    ],
                  ),
            if (_updating && mroom != null)
              Center(child: CircularProgressIndicator())
          ]);
        });
  }
}
