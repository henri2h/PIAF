import 'dart:async';

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
    "/stories",
    "/chat",
    "/events",
    "/community"
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
        child: AutoTabsRouter(
          builder: (context, widget) {
            final path = AutoRouterDelegate.of(context).urlState.uri.toString();
            controller?.add(path);

            final shouldDisplayAppBar = displayAppBarList.contains(path);
            final shouldDisplayNavigationRail = path.startsWith("/rooms");

            if (displayAppBar != shouldDisplayAppBar ||
                shouldDisplayNavigationRail != displayNavigationRail) {
              SchedulerBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  displayAppBar = shouldDisplayAppBar;
                  displayNavigationRail = shouldDisplayNavigationRail;
                });
              });
            }

            final tabsRouter = AutoTabsRouter.of(context);
            return Scaffold(
              body: Row(
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
                      Expanded(child: widget),
                    ],
                  )),
                ],
              ),
              bottomNavigationBar: isWideScreen || !displayAppBar
                  ? null
                  : NavigationBar(
                      selectedIndex: tabsRouter.activeIndex,
                      onDestinationSelected: (index) {
                        // here we switch between tabs
                        tabsRouter.setActiveIndex(index);
                      },
                      destinations: [
                        NavigationDestination(
                            icon: StreamBuilder(
                                stream:
                                    Matrix.of(context).onClientChange.stream,
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
                                              child: const Icon(Icons.message));
                                        }
                                      });
                                }),
                            label: "Chats"),
                        const NavigationDestination(
                            icon: Icon(Icons.feed), label: "Feed"),
                        const NavigationDestination(
                            icon: Icon(Icons.event), label: "Events "),
                        const NavigationDestination(
                            icon: Icon(Icons.group), label: "Community"),
                        const NavigationDestination(
                            icon: Icon(Icons.web_stories), label: "Stories"),
                      ],
                    ),
              endDrawer: const NotificationView(),
            );
          },
          routes: const [
            TabChatRoute(),
            TabHomeRoute(),
            TabCalendarRoute(),
            TabCommunityRoute(),
            TabStoriesRoute()
          ],
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
