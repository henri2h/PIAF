import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/users/userFeed.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';

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

  Widget? child;
  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;
    isUserPage = sclient.userID == widget.userID;

    return LayoutBuilder(
        builder: (context, constraints) => FutureBuilder<ProfileInformation>(
            future: sclient.getUserProfile(widget.userID),
            builder: (context, snap) {
              return Column(
                //controller: _controller,
                children: [
                  Builder(builder: (context) {
                    MinestrixRoom? mroom =
                        sclient.srooms[sclient.userIdToRoomId[widget.userID]];
                    if (mroom != null) {
                      return UserFeed(sroom: mroom);
                      /* UserInfo(
                          user: mroom.user,
                          avatar: mroom.room.avatar?.getDownloadLink(sclient));*/
                    }
                    return Text("Could not find this user room");
                  }),

                  // feed

                  if (child != null) child!
                ],
              );
            }));
  }
}
