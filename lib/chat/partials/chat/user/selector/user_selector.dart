import 'dart:async';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/chat/utils/text.dart';

import '../../../../style/constants.dart';
import '../../../matrix/matrix_image_avatar.dart';
import '../../../matrix/matrix_user_item.dart';

class UserSelectorController {
  List<String> selectedUsers = [];
}

class UserSelector extends StatefulWidget {
  const UserSelector(
      {super.key,
      required this.client,
      required this.multipleUserSelectionEnabled,
      required this.onUserSelected,
      required this.appBarBuilder,
      this.ignoreUsers = const [],
      required this.state});

  final Client client;
  final bool multipleUserSelectionEnabled;
  final UserSelectorController state;
  final Function(String) onUserSelected;
  final Widget Function(bool isSearching) appBarBuilder;
  final List<String> ignoreUsers;
  @override
  State<UserSelector> createState() => _UserSelectorState();
}

class _UserSelectorState extends State<UserSelector> {
  UserSelectorController get state => widget.state;

  final textController = TextEditingController();

  bool isSearching = false;
  Timer? _debounce;

  Future<List<Profile>>? _searchResultProfiles;
  Future<List<Profile>>? _searchResultLocalProfiles;
  List<String> get directChats => widget.client.directChats.keys.toList();

/*
/// It has been tried to display the list of all the directChats users. However due to their important
/// amount, it is inpossible. Indeed doing so takes too much time to do the network request and processing.
/// Therefore, this approach is inpracticable. :(
  Future<List<Profile>> loadList() async {
    final list = <Profile>[];
    for (final userId in directChats) {
      try {
        final profile = await widget.client.getProfileFromUserId(userId);
        list.add(profile);
      } catch (e) {
        Logs().e("Could not get $userId profile", e);
      }
    }
    return list
      ..sortBy((element) =>
          element.displayName?.toLowerCase().removeDiacritics() ?? '');
  }*/

  void onTextChanged(String text) {
    final oldState = isSearching;
    isSearching = text.isNotEmpty;

    if (!isSearching) {
      _debounce?.cancel();
      _searchResultLocalProfiles = Future(() => []);
      _searchResultProfiles = Future(() => []);
      _debounce = null;
    }

    if (isSearching != oldState) {
      setState(() {});
    }

    if (isSearching) {
      if (!(_debounce?.isActive ?? false)) {
        _debounce = Timer(const Duration(milliseconds: 300), () async {
          _searchResultProfiles = search(textController.text);
          _searchResultLocalProfiles = searchLocal(textController.text);
          if (mounted) setState(() {});
        });
      }
    }
  }

  Future<List<Profile>> searchLocal(String searchTerm) async {
    searchTerm =
        searchTerm.toLowerCase().removeDiacritics().removeSpecialCharacters();
    List<String?> users = widget.client.rooms
        .where((r) =>
            !r.isExtinct &&
            r.isDirectChat &&
            (r
                    .getLocalizedDisplayname()
                    .toLowerCase()
                    .removeDiacritics()
                    .removeSpecialCharacters()
                    .contains(searchTerm) ||
                r.canonicalAlias.contains(searchTerm) ||
                r.id.contains(searchTerm)))
        .map((e) => e.directChatMatrixID)
        .toList();

    final profiles = <Profile>[];

    for (final userId in users) {
      if (userId != null) {
        try {
          final user = await widget.client.getProfileFromUserId(userId);
          profiles.add(user);
        } catch (_) {}
      }
    }
    return profiles;
  }

  Future<List<Profile>> search(String searchTerm) async {
    final result = await widget.client.searchUserDirectory(searchTerm);
    if (searchTerm.isValidMatrixId) {
      try {
        final user = await widget.client.getProfileFromUserId(searchTerm);
        result.results.add(user);
      } catch (_) {}
    }
    return result.results;
  }

  void toggleUser(String userId) =>
      setUser(userId, !state.selectedUsers.contains(userId));

  void setUser(String userId, bool value) => value
      ? state.selectedUsers.add(userId)
      : state.selectedUsers.remove(userId);

  Widget buildItem(Widget item, String userId) {
    if (widget.multipleUserSelectionEnabled) {
      return InkWell(
        onTap: () => setState(() {
          toggleUser(userId);
        }),
        child: Row(
          children: [
            Expanded(child: item),
            Radio(
              value: state.selectedUsers.contains(userId),
              groupValue: true,
              toggleable: true,
              onChanged: (bool? value) {
                setState(() {
                  setUser(userId, !(value ?? true));
                });
              },
            ),
          ],
        ),
      );
    }
    return InkWell(onTap: () => widget.onUserSelected(userId), child: item);
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = directChats.take(20).toList();
    // TODO: Implement a smarter way to do chat suggestions

    return FutureBuilder<List<Profile>>(
        future: _searchResultLocalProfiles,
        builder: (context, snapLocal) {
          final localProfiles = snapLocal.data
                  ?.where((user) => !widget.ignoreUsers.contains(user.userId))
                  .toList() ??
              [];

          return FutureBuilder<List<Profile>>(
              future: _searchResultProfiles,
              builder: (context, snapProfiles) {
                final allProfiles = snapProfiles.data?.where(
                    (user) => !widget.ignoreUsers.contains(user.userId));
                // Filter all the local profiles
                final internetProfiles = allProfiles
                        ?.where(
                            (element) => !directChats.contains(element.userId))
                        .toList() ??
                    [];

                return CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    cacheExtent: 400,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        automaticallyImplyLeading: false,
                        flexibleSpace: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: textController,
                            onChanged: onTextChanged,
                            decoration: Constants.kTextFieldInputDecoration
                                .copyWith(
                                    labelText: "Search",
                                    prefixIcon: const Icon(Icons.search)),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                            (context, index) => (state.selectedUsers.isNotEmpty)
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2.0, horizontal: 6),
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(children: [
                                            for (final userId
                                                in state.selectedUsers)
                                              InkWell(
                                                  onTap: () => setState(() {
                                                        state.selectedUsers
                                                            .remove(userId);
                                                      }),
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 2,
                                                        horizontal: 4),
                                                    child: FutureBuilder<
                                                            Profile>(
                                                        future: widget.client
                                                            .getProfileFromUserId(
                                                                userId),
                                                        builder:
                                                            (context, snap) =>
                                                                Stack(
                                                                  children: [
                                                                    MatrixImageAvatar(
                                                                      client: widget
                                                                          .client,
                                                                      url: snap
                                                                          .data
                                                                          ?.avatarUrl,
                                                                      defaultText: snap
                                                                          .data
                                                                          ?.displayName,
                                                                    ),
                                                                    Positioned(
                                                                        top: 0,
                                                                        right:
                                                                            0,
                                                                        child: CircleAvatar(
                                                                            radius:
                                                                                7,
                                                                            backgroundColor: Theme.of(context)
                                                                                .colorScheme
                                                                                .primary,
                                                                            child: Icon(Icons.remove,
                                                                                size: 12,
                                                                                color: Theme.of(context).colorScheme.onPrimary)))
                                                                  ],
                                                                )),
                                                  ))
                                          ]),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Divider(),
                                      ),
                                    ],
                                  )
                                : widget.appBarBuilder(isSearching),
                            childCount: 1),
                      ),
                      if (suggestions.isNotEmpty == true && !isSearching)
                        SliverList.list(children: const [
                          ListTile(
                            title: Text("Suggestions"),
                          )
                        ]),
                      if (suggestions.isNotEmpty == true && !isSearching)
                        SliverList.builder(
                            itemBuilder: (context, pos) =>
                                FutureBuilder<Profile>(
                                    future: widget.client
                                        .getProfileFromUserId(suggestions[pos]),
                                    builder: (context, snapshot) {
                                      if (snapshot.data == null) {
                                        return const MatrixUserItemShimmer();
                                      }
                                      return buildProfile(snapshot.data!);
                                    }),
                            itemCount: suggestions.length),
                      if (localProfiles.isNotEmpty == true)
                        SliverList.list(children: const [
                          ListTile(
                            title: Text("Contacts"),
                          )
                        ]),
                      if (localProfiles.isNotEmpty == true)
                        SliverList.builder(
                          itemBuilder: (context, pos) {
                            final user = localProfiles[pos];

                            return Column(
                              children: [
                                buildProfile(user),
                              ],
                            );
                          },
                          itemCount: localProfiles.length,
                        ),
                      if (isSearching && !snapProfiles.hasData)
                        SliverList.builder(
                            itemBuilder: (context, pos) =>
                                const ListTile(title: MatrixUserItemShimmer()),
                            itemCount: 3),
                      if (internetProfiles.isNotEmpty == true)
                        SliverList.list(children: const [
                          ListTile(
                            title: Text("More contacts"),
                          )
                        ]),
                      if (internetProfiles.isNotEmpty == true)
                        SliverList.builder(
                            itemBuilder: (context, pos) =>
                                buildProfile(internetProfiles[pos]),
                            itemCount: internetProfiles.length)
                    ]);
              });
        });
  }

  Widget buildProfile(Profile user) {
    return buildItem(
        MatrixUserItem(
            avatarUrl: user.avatarUrl,
            client: widget.client,
            name: user.displayName,
            userId: user.userId),
        user.userId);
  }
}

/* In order to display the sorted profile list with name separators
SliverChildBuilderDelegate(
                                (context, pos) {
                                  final user = profiles[pos];
                                  final id = user.userId;

                                  final item = MatrixUserItem(
                                      avatarUrl: user.avatarUrl,
                                      client: widget.client,
                                      name: user.displayName,
                                      userId: id);

                                  String? userBefore;
                                  if (pos > 0) {
                                    userBefore = profiles[pos - 1]
                                        .displayName
                                        ?.substring(0, 1)
                                        .toLowerCase()
                                        .removeDiacritics();
                                  }
                                  final letter = user.displayName
                                      ?.substring(0, 1)
                                      .toLowerCase()
                                      .removeDiacritics();

                                  final shouldDisplayLetter =
                                      userBefore != letter;

                                  return shouldDisplayLetter
                                      ? Column(
                                          children: [
                                            if (shouldDisplayLetter)
                                              ListTile(
                                                title: Text(
                                                    letter?.toUpperCase() ??
                                                        "Error"),
                                              ),
                                            buildItem(item, id),
                                          ],
                                        )
                                      : buildItem(item, id);
                                },
                                childCount: profiles.length,
                              )
                               */
