import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:piaf/partials/minestrix_chat.dart';
import 'package:piaf/partials/utils/matrix_widget.dart';

import '../../pages/feed/feed_list_page.dart';
import '../../router.gr.dart';

class MinestrixNavigationRailItem {
  final Widget icon;
  final Widget label;
  final PageRouteInfo route;

  MinestrixNavigationRailItem(
      {required this.icon, required this.label, required this.route});
}

class MinestrixNavigationRail extends StatefulWidget {
  const MinestrixNavigationRail({
    super.key,
    required this.path,
  });

  final UrlState? path;
  @override
  State<MinestrixNavigationRail> createState() =>
      _MinestrixNavigationRailState();
}

class _MinestrixNavigationRailState extends State<MinestrixNavigationRail> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;

    final items = [
      MinestrixNavigationRailItem(
          icon: const Icon(Icons.home),
          label: const Text("Feed"),
          route: const FeedRoute()),
      MinestrixNavigationRailItem(
          icon: StreamBuilder(
              stream: client.onSync.stream,
              builder: (context, _) {
                int notif = client.chatNotificationsCount;
                if (notif == 0) {
                  return const Icon(Icons.message_outlined);
                } else {
                  return Badge.count(
                      count: notif, child: const Icon(Icons.message));
                }
              }),
          label: const Text("Chat"),
          route: const TabChatRoute()),
      MinestrixNavigationRailItem(
        icon: const Icon(Icons.event),
        label: const Text("Events"),
        route: const CalendarEventListRoute(),
      ),
      MinestrixNavigationRailItem(
          icon: const Icon(Icons.web_stories),
          label: const Text("Stories"),
          route: const TabStoriesRoute()),
      MinestrixNavigationRailItem(
          icon: const Icon(Icons.groups),
          label: const Text("Communities"),
          route: const TabCommunityRoute()),
      MinestrixNavigationRailItem(
          icon: const Icon(Icons.rss_feed),
          label: const Text("Feeds"),
          route: FeedListRoute(initialSelection: Selection.all)),
    ];

    var selectedIndex = items.indexWhere((element) {
      final list = widget.path?.segments.firstWhereOrNull(
          (segment) => element.route.routeName == segment.name);
      return list != null;
    });

    if (selectedIndex < 0 || selectedIndex >= items.length) selectedIndex = 0;

    return NavigationRail(
      // https://m3.material.io/components/navigation-rail/specs
      extended: expanded,
      labelType: NavigationRailLabelType.all,
      onDestinationSelected: (pos) => context.navigateTo(items[pos].route),
      leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: const Image(
            image: AssetImage('assets/piaf.jpg'),
            width: 50,
            height: 50,
          )),

      destinations: [
        ...items.map((e) => NavigationRailDestination(
            icon: e.icon, label: e.label, padding: const EdgeInsets.all(6)))
      ],

      selectedIndex: selectedIndex,
    );
  }
}
