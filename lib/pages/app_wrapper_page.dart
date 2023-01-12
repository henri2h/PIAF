import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/home/notification_view.dart';
import 'package:minestrix/partials/navbar.dart';
import 'package:minestrix/utils/minestrix/minestrix_notifications.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../router.gr.dart';

class AppWrapperPage extends StatefulWidget {
  const AppWrapperPage({Key? key}) : super(key: key);

  @override
  State<AppWrapperPage> createState() => _AppWrapperPageState();
}

class _AppWrapperPageState extends State<AppWrapperPage> {
  Future<void>? loadFuture;

  static const displayAppBarList = {"/search", "/feed", "/rooms", "/evnts"};

  /// bah dirty

  Future<void> load() async {
    final m = Matrix.of(context).client;
    await m.roomsLoading;
  }

  @override
  void initState() {
    super.initState();
  }

  bool displayAppBar = false;

  @override
  Widget build(BuildContext context) {
    loadFuture ??= load();

    final client = Matrix.of(context).client;

    Matrix.of(context).navigatorContext = context;
    Matrix.of(context).voipPlugin?.context = context;

    return LayoutBuilder(builder: (context, constraints) {
      bool isWideScreen = constraints.maxWidth > 850;

      return SafeArea(
        child: Scaffold(
          extendBody: true,
          body: Column(
            children: [
              if (isWideScreen) const NavBarDesktop(),
              Expanded(child: AutoRouter(
                builder: (context, widget) {
                  final shouldDisplayAppBar = displayAppBarList.contains(
                      AutoRouterDelegate.of(context).urlState.uri.toString());
                  if (displayAppBar != shouldDisplayAppBar) {
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        displayAppBar = shouldDisplayAppBar;
                      });
                    });
                  }
                  return widget;
                },
              )),
            ],
          ),
          bottomNavigationBar: isWideScreen || !displayAppBar
              ? null
              : SizedBox(
                  height: 58,
                  child: ClipRRect(
                      child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: BottomNavigationBar(
                            backgroundColor: Theme.of(context)
                                .scaffoldBackgroundColor
                                .withAlpha(180),
                            currentIndex: 0,
                            showSelectedLabels: false,
                            showUnselectedLabels: false,
                            iconSize: 24,
                            onTap: (pos) {
                              switch (pos) {
                                case 0:
                                  context.navigateTo(const FeedRoute());
                                  break;
                                case 1:
                                  context.navigateTo(
                                      const CalendarEventListRoute());
                                  break;
                                case 2:
                                  context.navigateTo(ResearchRoute());
                                  break;
                                case 3:
                                  context
                                      .navigateTo(const RoomListWrapperRoute());
                                  break;
                                default:
                              }
                            },
                            type: BottomNavigationBarType.fixed,
                            items: [
                              const BottomNavigationBarItem(
                                  icon: Icon(Icons.list), label: "Feed"),
                              const BottomNavigationBarItem(
                                  icon: Icon(Icons.event), label: "Event"),
                              const BottomNavigationBarItem(
                                  icon: Icon(Icons.search), label: "Search"),
                              BottomNavigationBarItem(
                                  icon: StreamBuilder(
                                      stream: client.onSync.stream,
                                      builder: (context, _) {
                                        int notif =
                                            client.totalNotificationsCount;
                                        if (notif == 0) {
                                          return const Icon(
                                              Icons.message_outlined);
                                        } else {
                                          return Stack(
                                            children: [
                                              const Icon(Icons.message),
                                              Padding(
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      vertical: 0,
                                                      horizontal: 20),
                                                  child: CircleAvatar(
                                                      radius: 9,
                                                      backgroundColor:
                                                          Colors.red,
                                                      child: Text(
                                                          notif.toString(),
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                          )))),
                                            ],
                                          );
                                        }
                                      }),
                                  label: "Chat"),
                            ],
                          ))),
                ),
          endDrawer: NotificationView(),
        ),
      );
    });
  }
}

class AvatarBottomBar extends StatefulWidget {
  const AvatarBottomBar({Key? key}) : super(key: key);

  @override
  State<AvatarBottomBar> createState() => _AvatarBottomBarState();
}

class _AvatarBottomBarState extends State<AvatarBottomBar> {
  Profile? lastProfile;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: Matrix.of(context).client.onSync.stream,
        builder: (context, snap) {
          return FutureBuilder(
              future: Matrix.of(context).client.fetchOwnProfile(),
              builder: (BuildContext context, AsyncSnapshot<Profile> p) {
                if (p.data != null) lastProfile = p.data;
                return MatrixImageAvatar(
                    client: Matrix.of(context).client,
                    url: lastProfile?.avatarUrl,
                    defaultText: lastProfile?.displayName ??
                        Matrix.of(context).client.userID,
                    fit: true);
              });
        });
  }
}
