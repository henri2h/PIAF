import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/pages/minestrix/postEditor.dart';
import 'package:minestrix/partials/components/account/accountCard.dart';
import 'package:minestrix/partials/components/buttons/customTextFutureButton.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/partials/feed/minestrixProfileNotCreated.dart';
import 'package:minestrix/partials/feed/notficationBell.dart';
import 'package:minestrix/partials/post/postView.dart';
import 'package:minestrix/partials/post/postWriterModal.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix_chat/partials/custom_list_view.dart';
import 'package:minestrix_chat/partials/stories/stories_list.dart';

class MinestrixFeed extends StatefulWidget {
  const MinestrixFeed({Key? key}) : super(key: key);

  @override
  _MinestrixFeedState createState() => _MinestrixFeedState();
}

class _MinestrixFeedState extends State<MinestrixFeed> {
  List<Event>? timeline;

  @override
  Widget build(BuildContext context) {
    MinestrixClient? sclient = Matrix.of(context).sclient;

    return StreamBuilder(
        stream: sclient!.onTimelineUpdate.stream,
        builder: (context, _) {
          if (sclient.stimeline.length == 0)
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      H1Title("Welcome on MinesTRIX"),
                      H2Title(sclient.userRoomCreated != true
                          ? "First time here ?"
                          : "Your timeline is empty"),
                      if (sclient.userRoomCreated != true)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: MinestrixProfileNotCreated(),
                        ),
                      if (sclient.userRoomCreated == true)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CustomTextFutureButton(
                              icon: Icon(Icons.post_add),
                              text: "Write your first post",
                              onPressed: () async {
                                context.pushRoute(PostEditorRoute());
                              }),
                        ),
                      if (sclient.userRoomCreated == true)
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
                        await sclient.updateAll();
                      }),
                ),
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

          return CustomListViewWithEmoji(
              itemCount: timeline!.length + 1,
              itemBuilder: (BuildContext c, int i,
                  void Function(Offset, Event) onReact) {
                if (i == 0) {
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
                                      context.pushRoute(CreateGroupRoute());
                                    }),
                                IconButton(
                                    icon: Icon(Icons.post_add),
                                    onPressed: () {
                                      context.pushRoute(PostEditorRoute());
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
                                NotificationBell()
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
                }

                return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                    child: Post(
                        event: timeline![i - 1],
                        onReact: (Offset e) => onReact(e, timeline![i - 1])));
              });
        });
  }
}
