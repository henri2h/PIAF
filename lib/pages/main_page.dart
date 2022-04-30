import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrix_notifications.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';

import '../partials/home/notificationView.dart';
import '../router.gr.dart';
import '../utils/matrix_widget.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(context) {
    Client client = Matrix.of(context).client;
    return LayoutBuilder(builder: (context, constraints) {
      bool isWideScreen = constraints.maxWidth > 900;
      return isWideScreen
          ? Scaffold(
              body: AutoRouter(),
              endDrawer: NotificationView(),
            )
          : AutoTabsScaffold(
              routes: [
                FeedRoute(),
                ResearchRoute(),
                MatrixChatsRoute(
                    client: Matrix.of(context).client,
                    allowPop: false,
                    onSelection: (String roomId) {
                      context.navigateTo(MatrixChatRoute(
                          client: Matrix.of(context).client,
                          roomId: roomId,
                          onBack: () => context.popRoute()));
                    }),
                UserRoute(userID: Matrix.of(context).client.userID),
              ],
              bottomNavigationBuilder: (_, tabsRouter) {
                return BottomNavigationBar(
                  currentIndex: tabsRouter.activeIndex,
                  onTap: tabsRouter.setActiveIndex,
                  type: BottomNavigationBarType.fixed,
                  items: [
                    BottomNavigationBarItem(
                        icon: Icon(Icons.list), label: "Feed"),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.search), label: "Search"),
                    BottomNavigationBarItem(
                        icon: StreamBuilder(
                            stream: client.onSync.stream,
                            builder: (context, _) {
                              int notif = client.totalNotificationsCount;
                              if (notif == 0) {
                                return Icon(Icons.message_outlined);
                              } else {
                                return Stack(
                                  children: [
                                    Icon(Icons.message),
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 3, horizontal: 15),
                                        child: CircleAvatar(
                                            radius: 11,
                                            backgroundColor: Colors.red,
                                            child: Text(notif.toString(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                )))),
                                  ],
                                );
                              }
                            }),
                        label: "Chat"),
                    BottomNavigationBarItem(
                        icon: SizedBox(
                          height: 30,
                          child: StreamBuilder(
                              stream: client.onSync.stream,
                              builder: (context, snapshot) {
                                print("build ${client.userID}");
                                return AvatarBottomBar(
                                    key: Key(client.userID!));
                              }),
                        ),
                        label: "My account"),
                  ],
                );
              },
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
  late Future<Profile> futureClient;
  @override
  void initState() {
    print("set state");
    futureClient = Matrix.of(context)
        .client
        .getProfileFromUserId(Matrix.of(context).client.userID!);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print("build");
    return FutureBuilder(
        future: futureClient,
        builder: (BuildContext context, AsyncSnapshot<Profile> p) {
          return MatrixImageAvatar(
              client: Matrix.of(context).client,
              url: p.data?.avatarUrl,
              defaultText:
                  p.data?.displayName ?? Matrix.of(context).client.userID,
              fit: true,
              thumnail: true);
        });
  }
}
