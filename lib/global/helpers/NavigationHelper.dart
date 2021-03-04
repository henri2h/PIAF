import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/post/postEditor.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrix/SMatrixRoom.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/screens/smatrix/groups/groupView.dart';
import 'package:minestrix/screens/smatrix/userFeedView.dart';

class NavigationHelper {
  static void navigateToUserFeed(BuildContext context, User user) {
    if (user != null)
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => Scaffold(
            appBar: AppBar(title: Text(user.displayName + " timeline")),
            body: UserFeedView(userId: user.id)),
      ));
  }

  static void navigateToWritePost(BuildContext context, SMatrixRoom sroom) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => Scaffold(
              appBar: AppBar(title: Text("Write post on " + sroom.name)),
              body: PostEditor(sroom: sroom),
            )));
  }

  static void navigateToGroup(BuildContext context, String roomID) {
    SClient sclient = Matrix.of(context).sclient;
    SMatrixRoom sroom =
        sclient.srooms[roomID]; // do not use sclient.sgroups as it's slower

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
          appBar: AppBar(title: Text(sroom.name + " timeline")),
          body: GroupView(sroom: sroom)),
    ));
  }
}
