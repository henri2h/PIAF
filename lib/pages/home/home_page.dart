import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:piaf/router.gr.dart';

import '../../chat/partials/sync/sync_status_card.dart';
import '../../chat/utils/matrix_widget.dart';
import '../../partials/account_selection_button.dart';
import '../feed/feed_list_page.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;

    return Scaffold(
        appBar: AppBar(
          leading: const AccountSelectionButton(),
          actions: [
            IconButton(
                onPressed: () async {
                  await context.navigateTo(SearchRoute());
                },
                icon: const Icon(Icons.explore))
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: 20, left: 30.0, right: 30, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset("assets/piaf.jpg",
                            width: 46, height: 46)),
                  ),
                  Text("PIAF",
                      style: Theme.of(context).textTheme.displayMedium),
                ],
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Events"),
                subtitle: const Text("Host and participate to events"),
                leading: const CircleAvatar(child: Icon(Icons.event)),
                onTap: () async {
                  await context.pushRoute(const CalendarEventListRoute());
                },
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Profiles"),
                subtitle: const Text("People you follow"),
                leading: const CircleAvatar(child: Icon(Icons.contacts)),
                onTap: () async {
                  await context.pushRoute(
                      FeedListRoute(initialSelection: Selection.feed));
                },
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Feeds"),
                subtitle: const Text("Feeds you follow"),
                leading: const CircleAvatar(child: Icon(Icons.feed)),
                onTap: () async {
                  await context.pushRoute(
                      FeedListRoute(initialSelection: Selection.publicFeed));
                },
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Communities"),
                subtitle: const Text("Organize your communities"),
                leading: const CircleAvatar(child: Icon(Icons.forum)),
                onTap: () async {
                  await context.pushRoute(const CommunityRoute());
                },
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Feeds agregation (Experimental)"),
                subtitle: const Text(
                    "Experimental way of using Matrix for social media"),
                leading: const CircleAvatar(child: Icon(Icons.dynamic_feed)),
                onTap: () async {
                  await context.pushRoute(const FeedRoute());
                },
              ),
            ),
            SyncStatusCard(client: client),
          ],
        ));
  }
}
