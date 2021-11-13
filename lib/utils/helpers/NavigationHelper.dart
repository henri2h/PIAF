import 'package:matrix/matrix.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/post/postEditor.dart';
import 'package:minestrix/pages/minestrix/groups/groupPage.dart';
import 'package:minestrix/pages/minestrix/userFeedPage.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';

class NavigationHelper {
  static void navigateToUserFeed(BuildContext context, User? user) {
    if (user != null)
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => Scaffold(
            appBar: AppBar(title: Text(user.displayName! + " timeline")),
            body: UserFeedPage(userId: user.id)),
      ));
  }

  static void navigateToWritePost(BuildContext context, MinestrixRoom? sroom) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => Scaffold(
              appBar: AppBar(title: Text("Write post on " + sroom!.name!)),
              body: PostEditor(sroom: sroom),
            )));
  }

  static void navigateToGroup(BuildContext context, String? roomID) {
    MinestrixClient sclient = Matrix.of(context).sclient!;
    MinestrixRoom? sroom =
        sclient.srooms[roomID!]; // do not use MinestrixClient.sgroups as it's slower

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
          appBar: AppBar(title: Text(sroom!.name! + " timeline")),
          body: GroupPage(sroom: sroom)),
    ));
  }
}
