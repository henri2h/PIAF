import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/router.gr.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
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
            ListTile(
              title: const Text("Events"),
              leading: const CircleAvatar(child: Icon(Icons.event)),
              onTap: () async {
                await context.pushRoute(const CalendarEventListRoute());
              },
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
          ],
        ));
  }
}
