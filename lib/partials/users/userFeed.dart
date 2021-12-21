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
import 'package:minestrix_chat/partials/stories_list.dart';

class UserFeed extends StatefulWidget {
  const UserFeed(
      {Key? key,
      required this.sroom,
      required this.sevents,
      required this.userID,
      this.isUserPage = false})
      : super(key: key);
  final MinestrixRoom sroom;
  final Iterable<Event> sevents;
  final String userID;

  /// change the way the partial is displayed.
  final bool isUserPage;

  @override
  _UserFeedState createState() => _UserFeedState();
}

class _UserFeedState extends State<UserFeed> {
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
    MinestrixClient sclient = Matrix.of(context).sclient!;
    return LayoutBuilder(
      builder: (context, constraints) => StreamBuilder(
          stream: widget.sroom.room.onUpdate.stream,
          builder: (context, _) => ListView(
                controller: _controller,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: H1Title(
                              widget.isUserPage ? "My account" : "User feed")),
                      if (widget.isUserPage)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 20),
                          child: Row(
                            children: [
                              IconButton(
                                  icon: Icon(Icons.settings),
                                  onPressed: () {
                                    context.navigateTo(SettingsRoute());
                                  }),
                            ],
                          ),
                        ),
                    ],
                  ),

                  UserInfo(
                      user: widget.sroom.user,
                      avatar:
                          widget.sroom.room.avatar?.getDownloadLink(sclient)),

                  if (constraints.maxWidth <= 900)
                    Column(
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(15),
                            child: UserFriendsCard(sroom: widget.sroom)),
                        MaterialButton(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("See all friends"),
                            ),
                            onPressed: () {
                              if (widget.isUserPage) {
                                context.navigateTo(FriendsRoute());
                              } else {
                                context.navigateTo(
                                    UserFriendsRoute(sroom: widget.sroom));
                              }
                            })
                      ],
                    ),

                  // feed

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (constraints.maxWidth > 900)
                        Flexible(
                          flex: 4,
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
                                        if (widget.isUserPage) {
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
                                client: sclient, restrict: widget.userID),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: PostWriterModal(sroom: sclient.userRoom),
                            ),
                            for (Event e in widget.sevents)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Post(event: e),
                              ),
                            if (widget.sevents.length == 0 ||
                                widget.sevents.last.type !=
                                    EventTypes.RoomCreate)
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
