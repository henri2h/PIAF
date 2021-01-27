import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/components/post/postView.dart';
import 'package:minestrix/components/postEditor.dart';
import 'package:minestrix/components/postWriterModal.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/screens/friendsVue.dart';

class FeedView extends StatelessWidget {
  const FeedView({
    Key key,
    @required this.sclient,
    this.changePage,
  }) : super(key: key);

  final Function changePage;

  final SClient sclient;

  @override
  Widget build(BuildContext context) {
    return Container(
      //color: Color(0xfff4f3f4),
      child: StreamBuilder(
        stream: sclient.onTimelineUpdate.stream,
        builder: (context, _) {
          print(sclient.stimeline.length.toString());
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
                        changePage(PostEditor());
                      }),
                ),
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: MinesTrixButton(
                      label: "Add some friends",
                      icon: Icons.person_add,
                      onPressed: () {
                        changePage(FriendsVue());
                      }),
                )
              ],
            );
          return ListView.builder(
              itemCount: sclient.stimeline.length + 1,
              itemBuilder: (BuildContext context, int i) {
                if (i == 0)
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: PostWriterModal(sroom: sclient.userRoom),
                  );
                return Padding(
                  padding: const EdgeInsets.all(8.0),
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
              });
        },
      ),
    );
  }
}
