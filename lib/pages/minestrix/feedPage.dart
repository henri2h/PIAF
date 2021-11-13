import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/components/post/postEditor.dart';
import 'package:minestrix/components/post/postView.dart';
import 'package:minestrix/components/post/postWriterModal.dart';
import 'package:minestrix/components/quickLinksList.dart';
import 'package:minestrix/pages/minestrix/friends/researchPage.dart';
import 'package:minestrix/pages/minestrix/groups/createGroup.dart';
import 'package:minestrix/partials/home/rightbar.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({Key key}) : super(key: key);

  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<Event> timeline;

  ScrollController _controller = new ScrollController();

  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient;

    return LayoutBuilder(builder: (context, constraints) {
      return StreamBuilder(
        stream: sclient.onTimelineUpdate.stream,
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
                        // changePage(PostEditor());
                      }),
                ),
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: MinesTrixButton(
                      label: "Add some friends",
                      icon: Icons.person_add,
                      onPressed: () {
                        // changePage(FriendsVue());
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

            print(sclient.stimeline.length);
            print(timeline.length);
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (constraints.maxWidth > 900)
                Flexible(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text("Groups",
                                style: TextStyle(
                                    fontSize: 22, letterSpacing: 1.1)),
                          ),
                          Expanded(child: QuickLinksBar())
                        ],
                      ),
                    )),
              Flexible(
                flex: 12,
                child: Container(
                  constraints: BoxConstraints(maxWidth: 700),
                  child: ListView.builder(
                      controller: _controller,
                      cacheExtent: 8000,
                      itemCount: timeline.length + 1,
                      itemBuilder: (BuildContext context, int i) {
                        if (i == 0)
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                                  builder: (_) =>
                                                      CreateGroup());
                                            }),
                                        IconButton(
                                            icon: Icon(Icons.post_add),
                                            onPressed: () {
                                              showDialog(
                                                  context: context,
                                                  builder: (_) => Scaffold(
                                                      appBar: AppBar(
                                                          title:
                                                              Text("New post")),
                                                      body: PostEditor()));
                                            }),
                                        IconButton(
                                            icon: Icon(Icons.search),
                                            onPressed: () {
                                              showDialog(
                                                  context: context,
                                                  builder: (_) => Scaffold(
                                                      appBar: AppBar(
                                                          title: Text(
                                                              "Search a user")),
                                                      body: ResearchPage()));
                                            }),
                                        IconButton(
                                            icon: Icon(Icons.notifications),
                                            onPressed: () {
                                              Scaffold.of(context)
                                                  .openEndDrawer();
                                            }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              PostWriterModal(sroom: sclient.userRoom),
                            ],
                          );
                        if (timeline.length >
                            0) // may be a redundant check... we never know
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 2, horizontal: 6),
                            child: Post(event: timeline[i - 1]),
                          );
                        else
                          return Text("Empty");
                      }),
                ),
              ),
              if (constraints.maxWidth > 900)
                Flexible(
                  flex: 4,
                  fit: FlexFit.loose,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(0),
                          child: Text("Contacts",
                              style:
                                  TextStyle(fontSize: 22, letterSpacing: 1.1)),
                        ),
                        Expanded(child: RightBar()),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      );
    });
  }
}
