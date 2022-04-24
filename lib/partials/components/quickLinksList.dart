import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrix_widget.dart';
import 'package:minestrix_chat/partials/sync/sync_status_card.dart';

class QuickLinksBar extends StatefulWidget {
  @override
  _QuickLinksBarState createState() => _QuickLinksBarState();
}

class _QuickLinksBarState extends State<QuickLinksBar>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    Client sclient = Matrix.of(context).client;
    return Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(
        children: [
          QuickLinkButton(
              name: "Feed",
              icon: Icons.home,
              onPressed: () async {
                await context.navigateTo(AppWrapperRoute());
                await context.navigateTo(FeedRoute());
              }),
          QuickLinkButton(
              name: "My account",
              icon: Icons.person,
              onPressed: () async {
                await context.navigateTo(AppWrapperRoute());
                await context.navigateTo(
                    UserViewRoute(userID: Matrix.of(context).client.userID));
              }),
          QuickLinkButton(
              name: "Chats",
              icon: Icons.chat,
              onPressed: () async {
                await context.navigateTo(MatrixChatsRoute(
                    client: Matrix.of(context).client, enableStories: true));
              }),
          QuickLinkButton(
              name: "Search",
              icon: Icons.search,
              onPressed: () async {
                await context.navigateTo(AppWrapperRoute());
                await context.navigateTo(ResearchRoute());
              }),
        ],
      ),
      SyncStatusCard(client: sclient),
      QuickLinkButton(
          onPressed: () async {
            await context.navigateTo(AppWrapperRoute());
            await context.navigateTo(SettingsRoute());
          },
          name: "Settings",
          icon: Icons.settings)
    ]);
  }
}

class QuickLinkButton extends StatelessWidget {
  const QuickLinkButton(
      {Key? key, this.name, this.icon, required this.onPressed})
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
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 26),
            if (name != null) SizedBox(width: 6),
            if (name != null)
              Text(name!,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
