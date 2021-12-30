import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/accountCard.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/pages/minestrix/postEditor.dart';
import 'package:minestrix/components/post/postView.dart';
import 'package:minestrix/components/post/postWriterModal.dart';
import 'package:minestrix/pages/minestrix/groups/createGroup.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix_chat/partials/stories/stories_list.dart';

class MinestrixFeed extends StatefulWidget {
  const MinestrixFeed({Key? key}) : super(key: key);

  @override
  _MinestrixFeedState createState() => _MinestrixFeedState();
}

class _MinestrixFeedState extends State<MinestrixFeed> {
  List<Event>? timeline;

  ScrollController _controller = new ScrollController();

  @override
  Widget build(BuildContext context) {
    MinestrixClient? sclient = Matrix.of(context).sclient;
    return StreamBuilder(
        stream: sclient!.onTimelineUpdate.stream,
        builder: (context, _) {
          if (sclient.stimeline.length == 0)
            return ListView(
              children: [
                H1Title("Timeline is empty"),
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: MinesTrixButton(
                      label: "Write your first post",
                      icon: Icons.post_add,
                      onPressed: () {
                        context.pushRoute(PostEditorRoute());
                      }),
                ),
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: MinesTrixButton(
                      label: "Add some friends",
                      icon: Icons.person_add,
                      onPressed: () {
                        context.pushRoute(FriendsRoute());
                      }),
                ),
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: MinesTrixButton(
                      label: "Refresh rooms",
                      icon: Icons.refresh,
                      onPressed: () async {
                        await sclient.updateAll();
                      }),
                )
              ],
            );

          /*
            In order to prevent the application to redraw the feed each time we recieve
            a new post, we make here a copy of the feed and refresh the feed only if the
            user press the reload button.

            TODO : display a notification that a new post is available
          */
          if (timeline == null)
            timeline = new List<Event>.from(sclient.stimeline); // deep copy
          else {
            // a new post may be available

            print("[ feedPage ] Timeline length : " +
                sclient.stimeline.length.toString());
            print("[ feedPage ] locale timeline length : " +
                timeline!.length.toString());
          }

          return ListView.builder(
              shrinkWrap: true,
              controller: _controller,
              cacheExtent: 8000,
              itemCount: timeline!.length + 1,
              itemBuilder: (BuildContext context, int i) {
                if (i == 0)
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          H1Title("Feed"),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                IconButton(
                                    icon: Icon(Icons.group_add),
                                    onPressed: () {
                                      showDialog(
                                          context: context,
                                          builder: (_) => CreateGroup());
                                    }),
                                IconButton(
                                    icon: Icon(Icons.post_add),
                                    onPressed: () {
                                      showDialog(
                                          context: context,
                                          builder: (_) => Scaffold(
                                              appBar: AppBar(
                                                  title: Text("New post")),
                                              body: PostEditorPage()));
                                    }),
                                IconButton(icon: Builder(builder: (context) {
                                  int notif = sclient.totalNotificationsCount;
                                  if (notif == 0) {
                                    return Icon(Icons.message_outlined);
                                  } else {
                                    return Stack(
                                      children: [
                                        Icon(Icons.message),
                                        Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 3, horizontal: 15),
                                            child: CircleAvatar(
                                                radius: 11,
                                                backgroundColor: Colors.red,
                                                child: Text(notif.toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                    )))),
                                      ],
                                    );
                                  }
                                }), onPressed: () async {
                                  await context.navigateTo(
                                      MatrixChatsRoute(client: sclient));
                                }),
                                StreamBuilder(
                                    stream: sclient
                                        .notifications.onNotifications.stream,
                                    builder: (BuildContext context,
                                        AsyncSnapshot snapshot) {
                                      return Column(
                                        children: [
                                          IconButton(
                                              icon: sclient
                                                          .notifications
                                                          .notifications
                                                          .length ==
                                                      0
                                                  ? Icon(
                                                      Icons.notifications_none)
                                                  : Icon(Icons
                                                      .notifications_active),
                                              onPressed: () {
                                                Scaffold.of(context)
                                                    .openEndDrawer();
                                              }),
                                        ],
                                      );
                                    })
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: StoriesList(client: sclient),
                      ),
                      PostWriterModal(sroom: sclient.userRoom),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: FutureBuilder<List<Profile>>(
                              future:
                                  sclient.friendsSuggestions.getSuggestions(),
                              builder: (context, snap) {
                                if (snap.hasData == false)
                                  return Text("Loading");
                                return Row(
                                  children: [
                                    for (Profile p in snap.data!)
                                      AccountCard(profile: p),
                                  ],
                                );
                              }),
                        ),
                      ),
                    ],
                  );
                if (timeline!.length >
                    0) // may be a redundant check... we never know
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                    child: Post(event: timeline![i - 1]),
                  );
                else
                  return Text("Empty");
              });
        });
  }
}
