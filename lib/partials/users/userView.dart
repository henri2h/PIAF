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

class UserView extends StatefulWidget {
  const UserView({Key? key, required this.userID}) : super(key: key);
  final String userID;

  @override
  _UserViewState createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  bool requestingHistory = false;
  bool _updating = false;

  late bool isUserPage;

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
        // await widget.sroom.timeline!.requestHistory();
        setState(() {
          _updating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;
    isUserPage = sclient.userID == widget.userID;

    return LayoutBuilder(
        builder: (context, constraints) => FutureBuilder<ProfileInformation>(
            future: sclient.getUserProfile(widget.userID),
            builder: (context, snap) {
              return ListView(
                controller: _controller,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child:
                              H1Title(isUserPage ? "My account" : "User feed")),
                      if (isUserPage)
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

                  Builder(builder: (context) {
                    MinestrixRoom? mroom = sclient.srooms[widget.userID];
                    if (mroom != null) {
                      return UserInfo(
                          user: mroom.user,
                          avatar: mroom.room.avatar?.getDownloadLink(sclient));
                    }
                    return Container();
                  }),

                  // feed

                  AutoRouter(),
                ],
              );
            }));
  }
}
