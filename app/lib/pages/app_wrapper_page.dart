import 'dart:async';
import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/home/notification_view.dart';
import 'package:minestrix/partials/navigation/navbar.dart';
import 'package:minestrix/utils/minestrix/minestrix_notifications.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../partials/navigation/navigation_rail.dart';
import '../router.gr.dart';

@RoutePage()
class AppWrapperPage extends StatefulWidget {
  const AppWrapperPage({Key? key}) : super(key: key);

  @override
  State<AppWrapperPage> createState() => _AppWrapperPageState();
}

class _AppWrapperPageState extends State<AppWrapperPage> {
  Future<void>? loadFuture;

  static const displayAppBarList = {
    "/",
    "/search",
    "/feed",
    "/rooms",
    "/events",
    "/communities"
  };

  /// bah dirty

  Future<void> load() async {
    final m = Matrix.of(context).client;
    await m.roomsLoading;
  }

  @override
  void initState() {
    super.initState();
    controller = StreamController.broadcast();
  }

  bool displayAppBar = false;
  bool displayNavigationRail = true;
  StreamController<String>? controller;

  @override
  Widget build(BuildContext context) {
    loadFuture ??= load();

    Matrix.of(context).navigatorContext = context;
    Matrix.of(context).voipPlugin?.context = context;

    return LayoutBuilder(builder: (context, constraints) {
      bool isWideScreen = constraints.maxWidth > 850;

      return SafeArea(
        child: Scaffold(
          extendBody: true,
          body: Column(
            children: [
              Expanded(
                  child: Row(
                children: [
                  if (isWideScreen)
                    StreamBuilder<String>(
                        stream: controller?.stream,
                        builder: (context, snapshot) {
                          return MinestrixNavigationRail(
                              path: snapshot.data ?? '');
                        }),
                  Expanded(
                    child: Column(
                      children: [
                        if (isWideScreen) const NavBarDesktop(),
                        if (isWideScreen)
                          const SizedBox(
                            height: 6,
                          ),
                        Expanded(
                          child: AutoRouter(
                            builder: (context, widget) {
                              final path = AutoRouterDelegate.of(context)
                                  .urlState
                                  .uri
                                  .toString();
                              controller?.add(path);

                              final shouldDisplayAppBar =
                                  displayAppBarList.contains(path);
                              final shouldDisplayNavigationRail =
                                  path.startsWith("/rooms");

                              if (displayAppBar != shouldDisplayAppBar ||
                                  shouldDisplayNavigationRail !=
                                      displayNavigationRail) {
                                SchedulerBinding.instance
                                    .addPostFrameCallback((_) {
                                  setState(() {
                                    displayAppBar = shouldDisplayAppBar;
                                    displayNavigationRail =
                                        shouldDisplayNavigationRail;
                                  });
                                });
                              }
                              return widget;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                                  context.navigateTo(const CommunityRoute());
                                  break;
                                case 3:
                                  context.navigateTo(ResearchRoute());
                                  break;
                                case 4:
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
                                  icon: Icon(Icons.group), label: "Community"),
                              const BottomNavigationBarItem(
                                  icon: Icon(Icons.search), label: "Search"),
                              BottomNavigationBarItem(
                                  icon: StreamBuilder(
                                      stream: Matrix.of(context)
                                          .onClientChange
                                          .stream,
                                      builder: (context, snap) {
                                        return StreamBuilder(
                                            stream: Matrix.of(context)
                                                .client
                                                .onSync
                                                .stream,
                                            builder: (context, _) {
                                              int notif = Matrix.of(context)
                                                  .client
                                                  .totalNotificationsCount;
                                              if (notif == 0) {
                                                return const Icon(
                                                    Icons.message_outlined);
                                              } else {
                                                return Badge.count(
                                                    count: notif,
                                                    child: const Icon(
                                                        Icons.message));
                                              }
                                            });
                                      }),
                                  label: "Chat"),
                            ],
                          ))),
                ),
          endDrawer: const NotificationView(),
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
