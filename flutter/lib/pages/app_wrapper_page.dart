import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:piaf/partials/home/notification_view.dart';
import 'package:piaf/utils/autoroute_observer.dart';
import 'package:piaf/utils/minestrix/minestrix_notifications.dart';
import 'package:piaf/utils/matrix_widget.dart';

import '../partials/navigation/navigation_rail.dart';
import '../router.gr.dart';

@RoutePage()
class AppWrapperPage extends StatefulWidget {
  const AppWrapperPage({super.key});

  @override
  State<AppWrapperPage> createState() => _AppWrapperPageState();
}

class _AppWrapperPageState extends State<AppWrapperPage> {
  static const displayAppBarList = {
    "/home",
    "/stories",
    "/todo",
    "/", // chat page
  };

  Future<bool>? loadFuture;
  Future<bool> load() async {
    final m = Matrix.of(context).client;
    await m.roomsLoading;
    return true;
  }

  StreamSubscription? subscription;
  @override
  void initState() {
    super.initState();
    controller = StreamController.broadcast();
    subscription = controller.stream.listen(onData);
  }

  void onData(String data) {
    setState(() {});
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  late StreamController<String> controller;

  @override
  Widget build(BuildContext context) {
    loadFuture ??= load();

    Matrix.of(context).navigatorContext = context;
    // TODO: See if the Voip View still display correctly even if the context is not beeing updated
    //Matrix.of(context).context = context;

    // Set the color of bellow the navigation bar
    setBellowNavigationBarColorForAndroid(context, true);

    return LayoutBuilder(builder: (context, constraints) {
      bool isWideScreen = constraints.maxWidth > 850;

      return FutureBuilder(
          future: loadFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData == false) {
              return Center(child: CircularProgressIndicator());
            }

            return AutoTabsRouter(
              navigatorObservers: () {
                return [MyObserver(controller)];
              },
              homeIndex: 1,
              builder: (context, widget) {
                final path = AutoRouterDelegate.of(context).urlState;
                bool shouldDisplayAppBar =
                    displayAppBarList.contains(path.uri.toString());

                final hideNavBar = isWideScreen || !shouldDisplayAppBar;

                final tabsRouter = AutoTabsRouter.of(context);

                return Scaffold(
                  body: Row(
                    children: [
                      if (isWideScreen) MinestrixNavigationRail(path: path),
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
                          backgroundColor: Colors.black,
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
                                label: "Chats"),
                            const NavigationDestination(
                                icon: Icon(Icons.web_stories),
                                label: "Stories"),
                          ],
                        ),
                );
              },
              routes: const [
                TabHomeRoute(),
                TabChatRoute(),
                TabStoriesRoute(),
              ],
            );
          });
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
