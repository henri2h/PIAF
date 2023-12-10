import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import 'lib.dart';

class UserSearch implements ItemManager<Profile> {
  String? nextBatch;
  late Client client;

  String searchText = "";

  @override
  Widget itemBuilder(BuildContext context, Profile profile) {
    return ListTile(
      leading: profile.avatarUrl == null
          ? const Icon(Icons.person)
          : MatrixImageAvatar(client: client, url: profile.avatarUrl),
      title: Text((profile.displayName ?? profile.userId)),
      subtitle: Text(profile.userId),
      onTap: () {
        Navigator.of(context).pop();
        context.navigateTo(UserViewRoute(userID: profile.userId));
      },
    );
  }

  @override
  Future<bool> requestMore() async {
    final response = await client.searchUserDirectory(searchText);
    items.clear();
    items.addAll(response.results);
    return true;
  }

  @override
  List<Profile> items = [];

  @override
  Future<void> setNewTerm(String text) async {
    searchText = text;
    nextBatch = null;
    items.clear();

    await requestMore();
  }

  @override
  void init(BuildContext context) {
    client = Matrix.of(context).client;
  }
}
