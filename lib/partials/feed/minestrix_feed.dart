import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/pages/minestrix/groups/create_group_page.dart';
import 'package:minestrix/partials/components/buttons/custom_text_future_button.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/partials/feed/minestrixProfileNotCreated.dart';
import 'package:minestrix/partials/feed/notficationBell.dart';
import 'package:minestrix/partials/post/post.dart';
import 'package:minestrix/partials/post/post_writer_modal.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix/utils/minestrix/minestrix_notifications.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/partials/custom_list_view.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/partials/stories/stories_list.dart';
import 'package:minestrix_chat/partials/sync/sync_status_card.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../../pages/app_wrapper_page.dart';
import '../../utils/settings.dart';
import '../components/friend_suggestion_list.dart';
import '../components/layouts/custom_header.dart';
import '../minestrix_title.dart';

class MinestrixFeed extends StatefulWidget {
  const MinestrixFeed({Key? key}) : super(key: key);

  @override
  MinestrixFeedState createState() => MinestrixFeedState();
}

class MinestrixFeedState extends State<MinestrixFeed> {
  Future<List<Event>>? futureEvents;
  late ScrollController controller;

  String? clientUserId;

  void resetPage() {
    futureEvents = null;
    init();
  }

  void init() {
    start = 0;
    _events.clear();
    isGettingEvents = false;

    final client = Matrix.of(context).client;

    clientUserId = client.userID;

    client.onMinestrixUpdate.listen((event) {});

    controller = ScrollController();
    controller.addListener(onScroll);
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  int start = 0;
  final List<Event> _events = [];
  bool isGettingEvents = false;

  Future<List<Event>> getEvents() async {
    if (!Settings().optimizedFeed) {
      return await Matrix.of(context).client.getMinestrixEvents();
    }
    if (_events.isNotEmpty) return _events;

    await requestEvents();
    return _events;
  }

  Future<List<Event>> requestEvents() async {
    if (isGettingEvents) return [];
    isGettingEvents = true;

    final client = Matrix.of(context).client;
    try {
      print("Get events start: $start");

      /*
      In order to prevent the application to redraw the feed each time we recieve
      a new post, we make here a copy of the feed and refresh the feed only if the
      user press the reload button.
      TODO : Put this system in place again
      TODO : display a notification that a new post is available
    */

      await client.roomsLoading;
      final events = await client.database?.getEventListFortype(
              MatrixTypes.post, client.rooms,
              start: start) ??
          [];

      start += events.length;

      final fevents = events
          .where((element) =>
              element.relationshipType == null && !element.redacted)
          .toList();
      _events.addAll(fevents);

      isGettingEvents = false;
      return fevents;
    } catch (_) {
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Object>(
        stream: Matrix.of(context).onClientChange.stream,
        builder: (context, snapshot) {
          Client? client = Matrix.of(context).client;

          if (client.userID != clientUserId) resetPage();

          return FutureBuilder(
              future: client.roomsLoading,
              builder: (context, _) {
                return FutureBuilder<List<Event>?>(
                    future: getEvents(),
                    builder: (context, snap) {
                      final events = snap.data;

                      if ((events?.length ?? 0) == 0) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ListView(
                                children: [
                                  const H1Title("Welcome on MinesTRIX"),
                                  client.prevBatch == null
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const MinestrixTitle(),
                                            SyncStatusCard(client: client),
                                          ],
                                        )
                                      : Column(
                                          children: [
                                            H2Title(
                                                client.userRoomCreated != true
                                                    ? "First time here ?"
                                                    : "Your timeline is empty"),
                                            if (client.userRoomCreated != true)
                                              const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child:
                                                    MinestrixProfileNotCreated(),
                                              ),
                                            if (client.userRoomCreated == true)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: CustomTextFutureButton(
                                                    icon: const Icon(
                                                        Icons.post_add),
                                                    text:
                                                        "Write your first post",
                                                    onPressed: () async {
                                                      context.pushRoute(
                                                          PostEditorRoute(
                                                              room: client
                                                                  .minestrixUserRoom));
                                                    }),
                                              ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: CustomTextFutureButton(
                                                  icon: const Icon(
                                                      Icons.group_add),
                                                  text: "Create a group",
                                                  onPressed: () async {
                                                    AdaptativeDialogs.show(
                                                        context: context,
                                                        builder: (context) =>
                                                            const CreateGroupPage());
                                                  }),
                                            ),
                                          ],
                                        ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 50,
                                left: 8.0,
                                right: 8,
                              ),
                              child: CustomTextFutureButton(
                                  icon: const Icon(Icons.refresh),
                                  text: "Refresh rooms",
                                  onPressed: () async {
                                    setState(() {});
                                  }),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          CustomHeader(
                              title: "Feed",
                              actionButton: [
                                IconButton(
                                    icon: const Icon(Icons.group_add),
                                    onPressed: () {
                                      AdaptativeDialogs.show(
                                          context: context,
                                          builder: (context) =>
                                              const CreateGroupPage());
                                    }),
                                const NotificationBell()
                              ],
                              child: MaterialButton(
                                  minWidth: 0,
                                  shape: const CircleBorder(),
                                  child:
                                      AvatarBottomBar(key: Key(client.userID!)),
                                  onPressed: () {
                                    context.pushRoute(UserViewRoute(
                                        userID:
                                            Matrix.of(context).client.userID));
                                  })),
                          Expanded(
                            child: CustomListViewWithEmoji(
                                itemCount: events!.length + 1,
                                controller: controller,
                                itemBuilder: (BuildContext c, int i,
                                    void Function(Offset, Event) onReact) {
                                  if (i == 0) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          child: StoriesList(client: client),
                                        ),
                                        if (client.minestrixUserRoom.isNotEmpty)
                                          PostWriterModal(), // TODO: set the actual rom we are displaying
                                        const FriendSuggestionsList(),
                                      ],
                                    );
                                  }

                                  return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Post(
                                          event: events[i - 1],
                                          onReact: (Offset e) =>
                                              onReact(e, events[i - 1])));
                                }),
                          ),
                        ],
                      );
                    });
              });
        });
  }
}
