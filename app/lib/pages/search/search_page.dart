import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/partials/search/providers/explore_search.dart';
import 'package:minestrix/partials/search/providers/user_search.dart';
import 'package:minestrix/partials/search/ui/lib.dart';
import 'package:minestrix_chat/style/constants.dart';

import '../../partials/components/search/suggestion_list.dart';
import '../../utils/platforms_info.dart';
import '../../models/search/search_mode.dart';

@RoutePage()
class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.isPopup = false, this.initialSearchMode});

  final bool isPopup;
  final SearchMode? initialSearchMode;

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final c = TextEditingController();

  final exploreSearch = ExploreSearch();
  final userSearch = UserSearch();

  SearchMode? searchMode;

  @override
  void initState() {
    super.initState();
    searchMode = widget.initialSearchMode;
    exploreSearch.init(context);
    userSearch.init(context);
  }

  Future<void> _callSearch(String searchText) async {
    if (searchMode == SearchMode.publicRoom) {
      await exploreSearch.setNewTerm(searchText);
    } else {
      await userSearch.setNewTerm(searchText);
    }
  }

  Timer? _debounce;
  _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      await _callSearch(query);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search")),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
              controller: c,
              autofocus: !PlatformInfos.isMobile,
              onChanged: _onSearchChanged,
              decoration: Constants.kTextFieldInputDecoration.copyWith(
                  prefix: searchMode != null
                      ? InputChip(
                          avatar: Icon(searchMode!.icon),
                          label: Text(searchMode!.text),
                          onDeleted: () {
                            setState(() {
                              searchMode = null;
                            });
                          },
                        )
                      : null)),
        ),
        if (searchMode == null)
          SearchBadges(
            onSearchModeSelected: (mode) {
              setState(() {
                searchMode = mode;
              });
            },
          ),
        Expanded(
          child: Builder(builder: (context) {
            if (searchMode == SearchMode.publicRoom) {
              return SearchSystem(
                manager: exploreSearch,
              );
            }

            if (c.text == "") {
              return ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  SuggestionList(shouldPop: widget.isPopup),
                ],
              );
            }

            return SearchSystem(
              manager: userSearch,
            );
          }),
        )
      ]),
    );
  }
}
