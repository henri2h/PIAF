import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/router.gr.dart';

import '../../chat/partials/sync/sync_status_card.dart';
import '../../chat/utils/matrix_widget.dart';

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
          title: const Text("Home"),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.notifications))
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
                leading: const CircleAvatar(child: Icon(Icons.event)),
                onTap: () async {
                  await context.pushRoute(const CalendarEventListRoute());
                },
              ),
            ),
            ListTile(
              title: const Text("Communities"),
              leading: const CircleAvatar(child: Icon(Icons.group)),
              onTap: () async {
                await context.pushRoute(const CommunityRoute());
              },
            ),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Experimental:"),
            ),
            ListTile(
              title: const Text("Feeds"),
              leading: const CircleAvatar(child: Icon(Icons.feed)),
              onTap: () async {
                await context.pushRoute(const FeedRoute());
              },
            ),
            SyncStatusCard(client: client),
          ],
        ));
  }
}
