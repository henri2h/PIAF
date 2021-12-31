import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/components/post/postView.dart';
import 'package:minestrix/components/post/postWriterModal.dart';
import 'package:minestrix/partials/users/userFriendsCard.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';
import 'package:minestrix_chat/partials/stories/stories_list.dart';

class UserFeed extends StatefulWidget {
  const UserFeed({Key? key, required this.sroom, this.isUserPage = false})
      : super(key: key);
  final MinestrixRoom sroom;

  /// change the way the partial is displayed.
  final bool isUserPage;

  @override
  _UserFeedState createState() => _UserFeedState();
}

class _UserFeedState extends State<UserFeed> {
  bool requestingHistory = false;

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

                  if (constraints.maxWidth <= 900)
                    Column(
                      children: [
                        MaterialButton(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("Followers"),
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
                        SizedBox(
                          width: 400,
                          child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: UserFriendsCard(sroom: widget.sroom)),
                        ),
                      Flexible(
                        flex: 9,
                        fit: FlexFit.loose,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 900),
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
                                  child: PostWriterModal(sroom: sroom),
                                ),
                                for (Event e in sevents)
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    child: Post(event: e, onReact: (e) {}),
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
                                                  padding:
                                                      const EdgeInsets.only(
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
                        ),
                      ),
                    ],
                  ),
                ],
              )),
    );
  }
}
