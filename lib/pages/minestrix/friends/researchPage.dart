import 'dart:async';

import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/layouts/customHeader.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';
import 'package:minestrix_chat/style/constants.dart';

import '../../../partials/components/search/suggestion_list.dart';

class ResearchPage extends StatefulWidget {
  @override
  _ResearchPageState createState() => _ResearchPageState();
}

class _ResearchPageState extends State<ResearchPage> {
  final c = TextEditingController();

  final discoveryStream = StreamController<SearchUserDirectoryResponse>();

  Future<void> _callSearch() async {
    Client? client = Matrix.of(context).client;
    print("search");
    discoveryStream.add(await client.searchUserDirectory(c.text));
  }

  Timer? _debounce;
  _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      await _callSearch();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Client? client = Matrix.of(context).client;
    return ListView(children: [
      CustomHeader(title: "Search"),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
            controller: c,
            onChanged: _onSearchChanged,
            decoration: Constants.kTextFieldInputDecoration),
      ),
      StreamBuilder<SearchUserDirectoryResponse>(
          stream: discoveryStream.stream,
          builder: (context, snap) {
            if (!snap.hasData || c.text == "") return SuggestionList();

            final list = snap.data!.results.toList();
            return Column(
              children: [
                for (final profile in list)
                  ListTile(
                    leading: profile.avatarUrl == null
                        ? Icon(Icons.person)
                        : MatrixImageAvatar(
                            client: client, url: profile.avatarUrl),
                    title: Text((profile.displayName ?? profile.userId)),
                    subtitle: Text(profile.userId),
                    onTap: () {
                      context.navigateTo(UserViewRoute(userID: profile.userId));
                    },
                  ),
              ],
            );
          })
    ]);
  }
}
