import 'package:flutter/material.dart';

import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrix_friends_suggestions.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix/utils/minestrix/minestrix_notifications.dart';
import 'package:minestrix_chat/partials/custom_list_view.dart';
import 'package:minestrix_chat/partials/stories/stories_list.dart';

import 'package:minestrix/partials/components/account/accountCard.dart';
import 'package:minestrix/partials/components/buttons/customTextFutureButton.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/partials/feed/minestrixProfileNotCreated.dart';
import 'package:minestrix/partials/feed/notficationBell.dart';
import 'package:minestrix/partials/post/postView.dart';
import 'package:minestrix/partials/post/postWriterModal.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrix_widget.dart';

import '../components/layouts/customHeader.dart';

class MinestrixFeed extends StatefulWidget {
  const MinestrixFeed({Key? key}) : super(key: key);

  @override
  _MinestrixFeedState createState() => _MinestrixFeedState();
}

class _MinestrixFeedState extends State<MinestrixFeed> {
  Future<List<Event>>? futureEvents;

  @override
  void initState() {
    super.initState();
  }

  Future<List<Event>> getEvents() async {
    // if (_events != null) return _events!;

    /*
      In order to prevent the application to redraw the feed each time we recieve
      a new post, we make here a copy of the feed and refresh the feed only if the
      user press the reload button.
      TODO : Put this system in place again
      TODO : display a notification that a new post is available
    */

    return await Matrix.of(context).client.getMinestrixEvents();
  }

  @override
  Widget build(BuildContext context) {
    Client? client = Matrix.of(context).client;

    return FutureBuilder(
        future: client.roomsLoading,
        builder: (context, _) {
          return StreamBuilder(
              stream: client.onMinestrixUpdate,
              builder: (context, snapshot) {
                return FutureBuilder<List<Event>?>(
                    future: getEvents(),
                    builder: (context, snap) {
                      final events = snap.data;

                      if ((events?.length ?? 0) == 0)
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ListView(
                                children: [
                                  H1Title("Welcome on MinesTRIX"),
                                  H2Title(client.userRoomCreated != true
                                      ? "First time here ?"
                                      : "Your timeline is empty"),
                                  if (client.userRoomCreated != true)
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: MinestrixProfileNotCreated(),
                                    ),
                                  if (client.userRoomCreated == true)
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: CustomTextFutureButton(
                                          icon: Icon(Icons.post_add),
                                          text: "Write your first post",
                                          onPressed: () async {
                                            context
                                                .pushRoute(PostEditorRoute());
                                          }),
                                    ),
                                  if (client.userRoomCreated == true)
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: CustomTextFutureButton(
                                          icon: Icon(Icons.person_add),
                                          text: "Add some followers",
                                          onPressed: () async {
                                            context.pushRoute(FriendsRoute());
                                          }),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: CustomTextFutureButton(
                                        icon: Icon(Icons.group_add),
                                        text: "Create a group",
                                        onPressed: () async {
                                          context.pushRoute(CreateGroupRoute());
                                        }),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CustomTextFutureButton(
                                  icon: Icon(Icons.refresh),
                                  text: "Refresh rooms",
                                  onPressed: () async {
                                    setState(() {});
                                  }),
                            ),
                          ],
                        );

                      return Column(
                        children: [
                          CustomHeader(title: "Feed", actionButton: [
                            IconButton(
                                icon: Icon(Icons.group_add),
                                onPressed: () {
                                  context.pushRoute(CreateGroupRoute());
                                }),
                            NotificationBell()
                          ]),
                          Expanded(
                            child: CustomListViewWithEmoji(
                                itemCount: events!.length + 1,
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
                                          PostWriterModal(
                                              room: client.minestrixUserRoom
                                                  .first), // TODO: set the actual rom we are displaying
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8.0, horizontal: 12),
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: FutureBuilder<List<Profile>>(
                                                future: client
                                                    .getFriendsSuggestions(),
                                                builder: (context, snap) {
                                                  if (snap.hasData == false)
                                                    return Text("Loading");
                                                  return Row(
                                                    children: [
                                                      for (Profile p
                                                          in snap.data!)
                                                        AccountCard(profile: p),
                                                    ],
                                                  );
                                                }),
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2, horizontal: 12),
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
