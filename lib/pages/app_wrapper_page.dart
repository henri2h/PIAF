import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:piaf/partials/home/notification_view.dart';
import 'package:piaf/utils/minestrix/minestrix_notifications.dart';
import 'package:piaf/partials/utils/matrix_widget.dart';

import '../partials/navigation/navigation_rail.dart';
import '../router.gr.dart';

@RoutePage()
class AppWrapperPage extends StatefulWidget {
  const AppWrapperPage({super.key});

  @override
  State<AppWrapperPage> createState() => _AppWrapperPageState();
}

class _AppWrapperPageState extends State<AppWrapperPage> {
  Future<void>? loadFuture;

  static const displayAppBarList = {
    "/home",
    "/stories",
    "/", // chat page
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
  StreamController<UrlState>? controller;

  @override
  Widget build(BuildContext context) {
    loadFuture ??= load();

    Matrix.of(context).navigatorContext = context;
    // TODO: See if the Voip View still display correctly even if the context is not beeing updated
    //Matrix.of(context).context = context;

    return LayoutBuilder(builder: (context, constraints) {
      bool isWideScreen = constraints.maxWidth > 850;

      return AutoTabsRouter(
        homeIndex: 1,
        builder: (context, widget) {
          final path = AutoRouterDelegate.of(context).urlState;
          controller?.add(path);

          bool shouldDisplayAppBar =
              displayAppBarList.contains(path.uri.toString());

          if (displayAppBar != shouldDisplayAppBar) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              setState(() {
                displayAppBar = shouldDisplayAppBar;
              });
            });
          }

          final hideNavBar = isWideScreen || !displayAppBar;

          setBellowNavigationBarColorForAndroid(context, hideNavBar);

          final tabsRouter = AutoTabsRouter.of(context);
          return Scaffold(
            body: Row(
              children: [
                if (isWideScreen)
                  StreamBuilder<UrlState>(
                      stream: controller?.stream,
                      builder: (context, snapshot) {
                        return MinestrixNavigationRail(path: snapshot.data);
                      }),
                Expanded(
                    child: Column(
                  children: [
                    if (isWideScreen)
                      const SizedBox(
                        height: 6,
                      ),
                    Expanded(child: widget),
                  ],
                )),
              ],
            ),
            bottomNavigationBar: hideNavBar
                ? null
                : NavigationBar(
                    selectedIndex: tabsRouter.activeIndex,
                    onDestinationSelected: (index) {
                      // here we switch between tabs
                      tabsRouter.setActiveIndex(index);
                    },
                    destinations: [
                      const NavigationDestination(
                          icon: Icon(Icons.home), label: "Home"),
                      NavigationDestination(
                          icon: StreamBuilder(
                              stream: Matrix.of(context).onClientChange.stream,
                              builder: (context, snap) {
                                return StreamBuilder(
                                    stream:
                                        Matrix.of(context).client.onSync.stream,
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
                          icon: Icon(Icons.web_stories), label: "Stories"),
                    ],
                  ),
            endDrawer: const NotificationView(),
          );
        },
        routes: const [
          TabHomeRoute(),
          TabChatRoute(),
          TabStoriesRoute(),
        ],
      );
    });
  }

  /// For android, color the area bellow the navigation bar. See https://m3.material.io/components/navigation-bar/specs And the navigation_bar.dart file.
  /// The use of the WidgetsBinding.instance.addPostFrameCallback is required so that the setSystemUIOverlayStyle is correctly called

  void setBellowNavigationBarColorForAndroid(
      BuildContext context, bool hideNavBar) {
    if (Platform.isAndroid) {
      final theme = Theme.of(context);

      final backgroundColor =
          theme.navigationBarTheme.backgroundColor ?? theme.colorScheme.surface;

      final color = ElevationOverlay.applySurfaceTint(
          backgroundColor,
          theme.navigationBarTheme.surfaceTintColor ??
              theme.colorScheme.surfaceTint,
          theme.navigationBarTheme.elevation ?? 3);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            systemNavigationBarColor: hideNavBar ? backgroundColor : color,
            systemNavigationBarIconBrightness: theme.brightness));
      });
    }
  }
}
