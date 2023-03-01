import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrix_community_extension.dart';
import 'package:minestrix/utils/minestrix/minestrix_notifications.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/partials/matrix/matrix_user_item.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../../pages/minestrix/friends/research_page.dart';
import '../../pages/settings/settings_account_switch_page.dart';
import '../../router.gr.dart';
import '../components/minestrix/minestrix_title.dart';
import '../minestrix_room_tile.dart';

class MinestrixNavigationRailItem {
  final Widget icon;
  final Widget label;
  final String path;
  final void Function(BuildContext) onDestinationSelected;

  MinestrixNavigationRailItem(
      {required this.icon,
      required this.label,
      required this.path,
      required this.onDestinationSelected});
}

class MinestrixNavigationRail extends StatefulWidget {
  const MinestrixNavigationRail({
    Key? key,
    required this.path,
  }) : super(key: key);

  final String path;
  @override
  State<MinestrixNavigationRail> createState() =>
      _MinestrixNavigationRailState();
}

class _MinestrixNavigationRailState extends State<MinestrixNavigationRail> {
  Future<void> showUserSelection(BuildContext context) async {
    await AdaptativeDialogs.show(
        context: context,
        builder: (context) => const SettingsAccountSwitchPage(
              popOnUserSelected: true,
            ));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    final items = [
      MinestrixNavigationRailItem(
          icon: const Icon(Icons.list),
          label: const Text("Feed"),
          path: const FeedRoute().path,
          onDestinationSelected: (BuildContext context) {
            context.navigateTo(const FeedRoute());
          }),
      MinestrixNavigationRailItem(
          icon: const Icon(Icons.person),
          label: const Text("My account"),
          path: UserViewRoute().path,
          onDestinationSelected: (BuildContext context) async {
            await context.navigateTo(
                UserViewRoute(userID: Matrix.of(context).client.userID));
          }),
      MinestrixNavigationRailItem(
          icon: const Icon(Icons.event),
          label: const Text("Event"),
          path: const CalendarEventListRoute().path,
          onDestinationSelected: (BuildContext context) async {
            context.navigateTo(const CalendarEventListRoute());
          }),
      MinestrixNavigationRailItem(
          icon: const Icon(Icons.groups),
          label: const Text("Communities"),
          path: const CommunityRoute().path,
          onDestinationSelected: (BuildContext context) async {
            context.navigateTo(const CommunityRoute());
          }),
      MinestrixNavigationRailItem(
          icon: const Icon(Icons.people),
          label: const Text("Feeds"),
          path: const FeedListRoute().path,
          onDestinationSelected: (BuildContext context) async {
            context.navigateTo(const FeedListRoute());
          }),
      MinestrixNavigationRailItem(
          icon: StreamBuilder(
              stream: client.onSync.stream,
              builder: (context, _) {
                int notif = client.totalNotificationsCount;
                if (notif == 0) {
                  return const Icon(Icons.message_outlined);
                } else {
                  return Badge.count(
                      count: notif, child: const Icon(Icons.message));
                }
              }),
          label: const Text("Chat"),
          path: const RoomListWrapperRoute().path,
          onDestinationSelected: (BuildContext context) async {
            context.navigateTo(const RoomListWrapperRoute());
          }),
      MinestrixNavigationRailItem(
          icon: const Icon(Icons.settings),
          label: const Text("Settings"),
          path: const SettingsRoute().path,
          onDestinationSelected: (BuildContext context) async {
            context.navigateTo(const SettingsRoute());
          }),
    ];

    var selectedIndex = items
        .indexWhere((element) => widget.path.startsWith("/${element.path}"));
    if (selectedIndex < 0 || selectedIndex >= items.length) selectedIndex = 0;

    return NavigationRail(
      extended: true,
      leading: SizedBox(
        width: 280,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/icon_512.png",
                      width: 40, height: 40, cacheHeight: 80, cacheWidth: 80),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text("MinesTRIX",
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            FutureBuilder<Profile>(
                future: client.fetchOwnProfile(),
                builder: (context, snap) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Card(
                      child: Row(
                        children: [
                          Expanded(
                            child: MatrixUserItem(
                              name: snap.data?.displayName,
                              userId: client.userID!,
                              avatarUrl: snap.data?.avatarUrl,
                              client: client,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: IconButton(
                                onPressed: () => showUserSelection(context),
                                icon: const Icon(Icons.arrow_drop_down_circle)),
                          )
                        ],
                      ),
                    ),
                  );
                }),
          ],
        ),
      ),
      onDestinationSelected: (pos) => items[pos].onDestinationSelected(context),
      destinations: [
        ...items
            .map((e) => NavigationRailDestination(icon: e.icon, label: e.label))
            .toList()
      ],
      selectedIndex: selectedIndex,
      trailing: Expanded(
        child: SizedBox(
          width: 270,
          child: ListView(
            children: [
              const H2Title("Communities"),
              for (final community in client.getCommunities())
                MinestrixRoomTileNavigator(room: community.space),
            ],
          ),
        ),
      ),
    );
  }
}
