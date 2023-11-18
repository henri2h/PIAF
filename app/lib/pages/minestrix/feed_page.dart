import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:minestrix/partials/navigation/rightbar.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix/utils/minestrix/minestrix_community_extension.dart';
import 'package:minestrix/utils/minestrix/minestrix_notifications.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/custom_list_view.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/partials/feed/posts/matrix_post_editor.dart';
import 'package:minestrix_chat/partials/sync/sync_status_card.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../../partials/account_selection_button.dart';
import '../../partials/components/layouts/layout_view.dart';
import '../../partials/components/minestrix/minestrix_title.dart';
import '../../partials/minestrix_room_tile.dart';
import '../../partials/minestrix_title.dart';
import '../../partials/post/post.dart';
import '../../utils/settings.dart';
import 'groups/create_group_page.dart';

@RoutePage()
class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  FeedPageState createState() => FeedPageState();
}

class FeedPageState extends State<FeedPage> {
  ScrollController controller = ScrollController();
  Future<void> launchCreatePostModal(BuildContext context) async {
    final client = Matrix.of(context).client;
    await PostEditorPage.show(
        context: context, rooms: client.minestrixUserRoom);
  }

  List<Event>? events;
  CachedStreamController<int> syncIdStream = CachedStreamController();
  StreamSubscription? listener;
  String? clientUserId;

  void resetPage() {
    isGettingEvents = false;
    start = 0;
    _databaseTimelineEvents.clear();
    events = null;
    listener?.cancel();
    init();
  }

  Future<void> loadEvents() async {
    await Matrix.of(context).client.roomsLoading;
    await getEvents();
    syncIdStream.add(syncIdStream.value ?? 0 + 1);
  }

  void init() {
    Logs().w("Timeline hooking up");
    final client = Matrix.of(context).client;

    clientUserId = client.userID;

    listener = client.onNewPost.listen((event) async {
      Logs().w("Timeline refreshing page");
      await loadEvents();
    });

    loadEvents();
  }

  @override
  void initState() {
    super.initState();
    init();

    controller.addListener(onScroll);
  }

  @override
  void deactivate() {
    listener?.cancel();
    super.deactivate();
  }

  int start = 0;
  final List<Event> _databaseTimelineEvents = [];

  bool isGettingEvents = false;

  Future<List<Event>> getEvents() async {
    if (!Settings().optimizedFeed) {
      events = await Matrix.of(context).client.getMinestrixEvents();
    } else {
      if (isGettingEvents) return events ?? [];
      events = await requestEvents();
    }
    return events!;
  }

  Future<List<Event>> requestEvents() async {
    if (isGettingEvents) return [];
    isGettingEvents = true;

    final client = Matrix.of(context).client;
    try {
      Logs().w("Request history $start");
      /*
      In order to prevent the application to redraw the feed each time we recieve
      a new post, we make here a copy of the feed and refresh the feed only if the
      user press the reload button.
      TODO : Put this system in place again
      TODO : display a notification that a new post is available
    */

      await client.roomsLoading;
      final events = await client.database?.getEventListForType(
              MatrixTypes.post, client.rooms,
              start: start) ??
          [];

      start += events.length;

      final fevents = events
          .where((element) =>
              element.relationshipType == null && !element.redacted)
          .toList();

      // adding events
      _databaseTimelineEvents.addAll(fevents);

      isGettingEvents = false;
      return _databaseTimelineEvents;
    } catch (ex, stack) {
      Logs().e("Timeline fetching error", ex, stack);
      isGettingEvents = false;
      return [];
    }
  }

  Future<void> onScroll() async {
    if (controller.position.maxScrollExtent - controller.position.pixels <
        800) {
      if (!Settings().optimizedFeed) return;

      await requestEvents();
      if (mounted) setState(() {});
    }
  }

  Future<bool> roomsLoadingTest(BuildContext context) async {
    await Matrix.of(context).client.roomsLoading;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          onPressed: () => launchCreatePostModal(context),
          child: const Icon(Icons.edit)),
      appBar: AppBar(title: const Text("Feed"), actions: [
        IconButton(
            onPressed: () async {
              await context.navigateTo(const RoomsExploreRoute());
            },
            icon: const Icon(Icons.explore)),
        IconButton(
            onPressed: () async {
              await context.navigateTo(SearchRoute());
            },
            icon: const Icon(Icons.search)),
        const AccountSelectionButton()
      ]),
      body: StreamBuilder<Object>(
          stream: Matrix.of(context).onClientChange.stream,
          builder: (context, snapshot) {
            Client? client = Matrix.of(context).client;

            if (client.userID != clientUserId) resetPage();

            return StreamBuilder<int>(
                stream: syncIdStream.stream,
                builder: (context, snap) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      resetPage();
                      await loadEvents();
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    child: LayoutView(
                        leftBar: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const H2Title("Communities"),
                            for (final community in client.getCommunities())
                              MinestrixRoomTileNavigator(room: community.space),
                          ],
                        ),
                        rightBar: const RightBar(),
                        mainBuilder: (
                                {required bool displaySideBar,
                                required bool displayLeftBar}) =>
                            events?.isNotEmpty != true
                                ? Column(
                                    children: [
                                      FutureBuilder(
                                          future: roomsLoadingTest(context),
                                          builder: (context, snap) {
                                            if (!snap.hasData) {
                                              return const CircularProgressIndicator();
                                            }
                                            return Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                ListView(
                                                  shrinkWrap: true,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  children: [
                                                    client.prevBatch == null
                                                        ? Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              const MinestrixTitle(),
                                                              SyncStatusCard(
                                                                  client:
                                                                      client),
                                                            ],
                                                          )
                                                        : Card(
                                                            child:
                                                                OnboardingWidget(
                                                                    client:
                                                                        client),
                                                          ),
                                                  ],
                                                ),
                                              ],
                                            );
                                          }),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      CustomListViewWithEmoji(
                                          itemCount: events!.length,
                                          controller: controller,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemBuilder: (BuildContext c,
                                              int i,
                                              void Function(Offset, Event)
                                                  onReact) {
                                            return Post(
                                                event: events![i],
                                                key: Key(events![i].eventId +
                                                    events![i]
                                                        .status
                                                        .toString()),
                                                onReact: (Offset e) =>
                                                    onReact(e, events![i]));
                                          }),
                                    ],
                                  )),
                  );
                });
          }),
    );
  }
}

class OnboardingWidget extends StatelessWidget {
  const OnboardingWidget({
    super.key,
    required this.client,
  });
  final Client client;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(28.0),
          child: Center(
            child: Text(
              "Welcome in MinesTRIX",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
          child: Text(
            "Onboarding",
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        WelcomeActionsButton(
            icon: Icons.people,
            text: 'Create your page',
            subtitle: 'That\'s where you can post',
            onPressed: () async {
              if (client.userRoomCreated) {
                await context.navigateTo(
                    UserViewRoute(userID: Matrix.of(context).client.userID));
              } else {
                await client.createPrivateMinestrixProfile();
              }
            },
            done: client.userRoomCreated),
        if (client.userRoomCreated == true)
          WelcomeActionsButton(
              icon: Icons.post_add,
              text: 'Post',
              subtitle: "Write a post on your page",
              onPressed: () async {
                await PostEditorPage.show(
                    context: context, rooms: client.minestrixUserRoom);
              },
              done: false),
        WelcomeActionsButton(
            icon: Icons.public,
            text: 'Publish your page',
            subtitle:
                'To help your find your page you can add it to your user space',
            onPressed: () async {
              context.pushRoute(const AccountsDetailsRoute());
            },
            done: false),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
          child: Text(
            "Go further",
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        WelcomeActionsButton(
            text: 'Story',
            subtitle: 'Create and manage your story page',
            icon: Icons.web_stories,
            onPressed: () async {
              context.pushRoute(const SettingsStorysRoute());
            },
            done: false),
        WelcomeActionsButton(
            icon: Icons.group_work,
            text: 'Create your group page',
            subtitle: 'A place to share posts',
            onPressed: () async {
              AdaptativeDialogs.show(
                  context: context,
                  builder: (context) => const CreateGroupPage());
            },
            done: false),
        WelcomeActionsButton(
            text: 'Explore',
            subtitle: 'Discover public pages',
            icon: Icons.explore,
            onPressed: () async {
              context.pushRoute(const RoomsExploreRoute());
            },
            done: false),
      ],
    );
  }
}

class WelcomeActionsButton extends StatelessWidget {
  const WelcomeActionsButton(
      {super.key,
      required this.text,
      required this.icon,
      required this.onPressed,
      required this.subtitle,
      required this.done});

  final String text;
  final String subtitle;
  final IconData icon;
  final Future<void> Function() onPressed;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 4,
        child: ListTile(
          leading: Icon(icon),
          title: Text(text),
          subtitle: Text(subtitle),
          onTap: done ? null : onPressed,
          trailing: done
              ? CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(
                    Icons.done,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ))
              : null,
        ),
      ),
    );
  }
}
