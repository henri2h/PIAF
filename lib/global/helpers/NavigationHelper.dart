import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/screens/userFeedView.dart';

class NavigationHelper {
  static void navigateToUserFeed(BuildContext context, User user) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
          appBar: AppBar(title: Text(user.displayName + " timeline")),
          body: UserFeedView(userId: user.id)),
    ));
  }
}
