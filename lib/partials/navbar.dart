import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/partials/feed/notficationBell.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

class NavBarDesktop extends StatelessWidget {
  const NavBarDesktop({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text("MinesTRIX",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          ),
          Row(
            children: [
              NavBarButton(
                  name: "Feed",
                  icon: Icons.home,
                  onPressed: () async {
                    await context.navigateTo(AppWrapperRoute());
                    await context.navigateTo(FeedRoute());
                  }),
              NavBarButton(
                  name: "My account",
                  icon: Icons.person,
                  onPressed: () async {
                    await context.navigateTo(AppWrapperRoute());
                    await context.navigateTo(UserViewRoute(
                        userID: Matrix.of(context).client.userID));
                  }),
              NavBarButton(
                  name: "Chats",
                  icon: Icons.chat,
                  onPressed: () async {
                    await context.navigateTo(MatrixChatsRoute(
                        client: Matrix.of(context).client,
                        enableStories: true));
                  }),
              NavBarButton(
                  name: "Search",
                  icon: Icons.search,
                  onPressed: () async {
                    await context.navigateTo(AppWrapperRoute());
                    await context.navigateTo(ResearchRoute());
                  }),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: NotificationBell(),
          ),
        ],
      ),
    );
  }
}

class NavBarButton extends StatelessWidget {
  const NavBarButton({Key? key, this.name, this.icon, required this.onPressed})
      : super(key: key);
  final String? name;
  final IconData? icon;
  final Function onPressed;
  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed as void Function()?,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 26),
            if (name != null) SizedBox(width: 6),
            if (name != null)
              Text(name!,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
