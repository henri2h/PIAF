import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';

import '../router.gr.dart';
import '../utils/matrixWidget.dart';
import '../utils/minestrix/minestrixClient.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;
    return AutoTabsScaffold(
      routes: [
        FeedRoute(),
        ResearchRoute(),
        UserRoute(userID: sclient.userID),
        MatrixChatsRoute(
            client: Matrix.of(context).sclient!,
            allowPop: false,
            onSelection: (String roomId) {
              context.navigateTo(MatrixChatRoute(
                  client: Matrix.of(context).sclient!,
                  roomId: roomId,
                  onBack: () => context.popRoute()));
            })
      ],
      bottomNavigationBuilder: (_, tabsRouter) {
        return BottomNavigationBar(
          currentIndex: tabsRouter.activeIndex,
          onTap: tabsRouter.setActiveIndex,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined), label: 'Feed'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
            BottomNavigationBarItem(
                icon: SizedBox(
                  height: 30,
                  child: FutureBuilder(
                      future: sclient.getProfileFromUserId(sclient.userID!),
                      builder:
                          (BuildContext context, AsyncSnapshot<Profile> p) {
                        if (p.data?.avatarUrl == null)
                          return Icon(Icons.person);
                        return MatrixImageAvatar(
                            client: sclient,
                            url: p.data!.avatarUrl,
                            fit: true,
                            thumnail: true);
                      }),
                ),
                label: "My account"),
            BottomNavigationBarItem(icon: Icon(Icons.message), label: "Chat"),
          ],
        );
      },
    );
  }
}
