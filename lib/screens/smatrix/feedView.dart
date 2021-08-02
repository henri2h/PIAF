import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/components/post/postEditor.dart';
import 'package:minestrix/components/post/postView.dart';
import 'package:minestrix/components/post/postWriterModal.dart';
import 'package:minestrix/components/quickLinksList.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/screens/home/right_bar/widget.dart';
import 'package:minestrix/screens/smatrix/friends/researchView.dart';
import 'package:minestrix/screens/smatrix/groups/createGroup.dart';

class FeedView extends StatelessWidget {
  const FeedView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;

    return LayoutBuilder(builder: (context, constraints) {
      return StreamBuilder(
        stream: sclient.onNewPostInTimeline.stream,
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
                      cacheExtent: 8000,
                      itemCount: sclient.stimeline.length + 1,
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
                                                      body: ResearchView()));
                                            }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              PostWriterModal(sroom: sclient.userRoom),
                            ],
                          );
                        if (sclient.stimeline.length > 0)
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 2, horizontal: 6),
                            child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.all(0),
                                  child: Post(event: sclient.stimeline[i - 1]),
                                )),
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
