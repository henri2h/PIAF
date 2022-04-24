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
                UserRoute(userID: client.userID),
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
                          child: FutureBuilder(
                              future:
                                  client.getProfileFromUserId(client.userID!),
                              builder: (BuildContext context,
                                  AsyncSnapshot<Profile> p) {
                                if (p.data?.avatarUrl == null)
                                  return Icon(Icons.person);
                                return MatrixImageAvatar(
                                    client: client,
                                    url: p.data!.avatarUrl,
                                    fit: true,
                                    thumnail: true);
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
