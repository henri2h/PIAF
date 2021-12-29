import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/components/post/postView.dart';
import 'package:minestrix/components/post/postWriterModal.dart';
import 'package:minestrix/partials/users/userFriendsCard.dart';
import 'package:minestrix/partials/users/userInfo.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';
import 'package:minestrix_chat/partials/stories/stories_list.dart';

class UserFeedPage extends StatefulWidget {
  const UserFeedPage({Key? key, required this.sroom}) : super(key: key);
  final MinestrixRoom sroom;

  @override
  _UserFeedPageState createState() => _UserFeedPageState();
}

class _UserFeedPageState extends State<UserFeedPage> {
  bool requestingHistory = false;
  bool _updating = false;

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
        await widget.sroom.timeline!.requestHistory();
        setState(() {
          _updating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    MinestrixRoom sroom = widget.sroom;
    MinestrixClient sclient = Matrix.of(context).sclient!;

    Iterable<Event> sevents = sclient
        .getSRoomFilteredEvents(widget.sroom.timeline!, eventTypesFilter: [
      EventTypes.Message,
      EventTypes.Encrypted,
      EventTypes.RoomCreate,
      EventTypes.RoomAvatar,
      EventTypes.RoomMember
    ]).where((Event e) {
      if (e.type == EventTypes.RoomMember) {
        if (e.prevContent != null &&
            e.content["avatar_url"] != e.prevContent!["avatar_url"] &&
            e.senderId == widget.sroom.user.id) {
          // the room owner has changed it's profile picture
          return true;
        }
        return false;
      }
      return true;
    });

    return LayoutBuilder(
      builder: (context, constraints) => StreamBuilder(
          stream: widget.sroom.room.onUpdate.stream,
          builder: (context, _) => Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (constraints.maxWidth > 900)
                        SizedBox(
                          width: 400,
                          child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                children: [
                                  UserFriendsCard(sroom: widget.sroom),
                                  MaterialButton(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text("See all friends"),
                                      ),
                                      onPressed: () {
                                        if (sroom.isUserPage) {
                                          context.navigateTo(FriendsRoute());
                                        } else {
                                          context.navigateTo(UserFriendsRoute(
                                              sroom: widget.sroom));
                                        }
                                      })
                                ],
                              )),
                        ),
                      Flexible(
                        flex: 9,
                        fit: FlexFit.loose,
                        child: Column(
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
                                client: sclient, restrict: sroom.userID),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: PostWriterModal(sroom: sclient.userRoom),
                            ),
                            for (Event e in sevents)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Post(event: e),
                              ),
                            if (sevents.length == 0 ||
                                sevents.last.type != EventTypes.RoomCreate)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: MaterialButton(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (requestingHistory)
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
                                      if (requestingHistory == false) {
                                        setState(() {
                                          requestingHistory = true;
                                        });
                                        await widget.sroom.room
                                            .requestHistory();
                                        setState(() {
                                          requestingHistory = false;
                                        });
                                      }
                                    }),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              )),
    );
  }
}
