import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/partials/home/notificationView.dart';
import 'package:minestrix/partials/navbar.dart';

class AppWrapperPage extends StatelessWidget {
  const AppWrapperPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        bool isWideScreen = constraints.maxWidth > 900;
        return Column(
          children: [
            if (isWideScreen) NavBarDesktop(),
            Expanded(child: AutoRouter()),
          ],
        );
      }),
      endDrawer: NotificationView(),
    );
  }
}
