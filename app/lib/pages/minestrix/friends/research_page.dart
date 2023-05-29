import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/layouts/custom_header.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/style/constants.dart';

import '../../../partials/components/search/suggestion_list.dart';
import '../../../utils/platforms_info.dart';

@RoutePage()
class ResearchPage extends StatefulWidget {
  const ResearchPage({Key? key, this.isPopup = false}) : super(key: key);

  final bool isPopup;
  @override
  ResearchPageState createState() => ResearchPageState();
}

class ResearchPageState extends State<ResearchPage> {
  final c = TextEditingController();

  final discoveryStream = StreamController<SearchUserDirectoryResponse>();

  Future<void> _callSearch() async {
    Client? client = Matrix.of(context).client;
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
    return Column(
      children: [
        if (!widget.isPopup) const CustomHeader(title: "Search"),
        Expanded(
          child: ListView(children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                  controller: c,
                  autofocus: !PlatformInfos.isMobile,
                  onChanged: _onSearchChanged,
                  decoration: Constants.kTextFieldInputDecoration),
            ),
            StreamBuilder<SearchUserDirectoryResponse>(
                stream: discoveryStream.stream,
                builder: (context, snap) {
                  if (!snap.hasData || c.text == "") {
                    return SuggestionList(shouldPop: widget.isPopup);
                  }

                  final list = snap.data!.results.toList();
                  return Column(
                    children: [
                      for (final profile in list)
                        ListTile(
                          leading: profile.avatarUrl == null
                              ? const Icon(Icons.person)
                              : MatrixImageAvatar(
                                  client: client, url: profile.avatarUrl),
                          title: Text((profile.displayName ?? profile.userId)),
                          subtitle: Text(profile.userId),
                          onTap: () {
                            Navigator.of(context).pop();
                            context.navigateTo(
                                UserViewRoute(userID: profile.userId));
                          },
                        ),
                    ],
                  );
                })
          ]),
        ),
      ],
    );
  }
}
