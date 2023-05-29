import 'dart:async';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../../../style/constants.dart';
import '../../matrix/matrix_image_avatar.dart';
import '../../matrix/matrix_user_item.dart';

class UserSelectorController {
  List<String> selectedUsers = [];
}

class UserSelector extends StatefulWidget {
  const UserSelector(
      {Key? key,
      required this.client,
      required this.multipleUserSelectionEnabled,
      required this.onUserSelected,
      required this.appBarBuilder,
      this.ignoreUsers = const [],
      required this.controller})
      : super(key: key);

  final Client client;
  final bool multipleUserSelectionEnabled;
  final UserSelectorController controller;
  final Function(String) onUserSelected;
  final Widget Function(bool isSearching) appBarBuilder;
  final List<String> ignoreUsers;
  @override
  State<UserSelector> createState() => _UserSelectorState();
}

class _UserSelectorState extends State<UserSelector> {
  final controller = TextEditingController();

  bool isSearching = false;

  Future<List<Profile>>? profiles;

  Timer? _debounce;

  void onTextChanged(String text) {
    final oldState = isSearching;
    isSearching = text.isNotEmpty;

    if (isSearching != oldState) {
      setState(() {});
    }

    if (isSearching) {
      if (profiles == null) {
        profiles = search();
        return;
      }

      if (!(_debounce?.isActive ?? false)) {
        _debounce = Timer(const Duration(milliseconds: 300), () async {
          profiles = search();
          if (mounted) setState(() {});
        });
      }
    }
  }

  Future<List<Profile>> search() async {
    final result = await widget.client.searchUserDirectory(controller.text);

    return result.results;
  }

  Widget buildItem(Widget item, String userId) {
    if (widget.multipleUserSelectionEnabled) {
      return CheckboxListTile(
        title: item,
        value: widget.controller.selectedUsers.contains(userId),
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              widget.controller.selectedUsers.add(userId);
            } else {
              widget.controller.selectedUsers.remove(userId);
            }
          });
        },
      );
    }
    return ListTile(title: item, onTap: () => widget.onUserSelected(userId));
  }

  @override
  Widget build(BuildContext context) {
    final chats = widget.client.directChats.keys
        .toList()
        .where((userId) => !widget.ignoreUsers.contains(userId))
        .toList();
    return Column(
      children: [
        Expanded(
            child: FutureBuilder<List<Profile>>(
                future: profiles,
                builder: (context, snapProfiles) {
                  final profileChats = snapProfiles.data
                      ?.where(
                          (user) => !widget.ignoreUsers.contains(user.userId))
                      .toList();

                  return CustomScrollView(
                      cacheExtent: 400,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverAppBar(
                          automaticallyImplyLeading: false,
                          flexibleSpace: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: controller,
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
                              (context, index) => (widget.controller
                                          .selectedUsers.isNotEmpty &&
                                      !isSearching)
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
                                              for (final userId in widget
                                                  .controller.selectedUsers)
                                                InkWell(
                                                    onTap: () => setState(() {
                                                          widget.controller
                                                              .selectedUsers
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
                                                                        client:
                                                                            widget.client,
                                                                        url: snap
                                                                            .data
                                                                            ?.avatarUrl,
                                                                        defaultText: snap
                                                                            .data
                                                                            ?.displayName,
                                                                      ),
                                                                      Positioned(
                                                                          top:
                                                                              0,
                                                                          right:
                                                                              0,
                                                                          child: CircleAvatar(
                                                                              radius: 7,
                                                                              backgroundColor: Theme.of(context).colorScheme.primary,
                                                                              child: Icon(Icons.remove, size: 12, color: Theme.of(context).colorScheme.onPrimary)))
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
                        SliverList(
                            delegate: !isSearching
                                ? SliverChildBuilderDelegate(
                                    (context, pos) {
                                      final id = chats[pos];
                                      return FutureBuilder<Profile>(
                                          future: widget.client
                                              .getProfileFromUserId(id),
                                          builder: (context, snap) {
                                            final user = snap.data;
                                            final item = MatrixUserItem(
                                                avatarUrl: user?.avatarUrl,
                                                client: widget.client,
                                                name: user?.displayName,
                                                userId: id);

                                            return buildItem(item, id);
                                          });
                                    },
                                    childCount: chats.length,
                                  )
                                : profileChats == null
                                    ? SliverChildBuilderDelegate(
                                        (context, pos) => const ListTile(
                                            title: MatrixUserItemShimmer()),
                                        childCount: 3)
                                    : SliverChildBuilderDelegate(
                                        (context, pos) {
                                          final user = profileChats[pos];
                                          final item = MatrixUserItem(
                                              avatarUrl: user.avatarUrl,
                                              client: widget.client,
                                              name: user.displayName,
                                              userId: user.userId);
                                          return buildItem(item, user.userId);
                                        },
                                        childCount: chats.length,
                                      )),
                      ]);
                })),
      ],
    );
  }
}
