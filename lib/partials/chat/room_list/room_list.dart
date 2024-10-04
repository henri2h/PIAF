import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/pages/chat/chat_lib/chat_page_items/chat_page_spaces_list.dart';
import 'package:piaf/pages/chat/chat_lib/chat_page_items/provider/chat_page_state.dart';
import 'package:piaf/partials/chat/room_list/room_list_items/room_list_item.dart';
import 'package:piaf/router.gr.dart';

import '../../../pages/chat/chat_lib/room_create/create_chat_page.dart';
import '../../account_selection_button.dart';
import '../search/matrix_chats_search.dart';
import '../spaces/list/spaces_list.dart';
import 'custom_list/no_rooms_list.dart';
import 'custom_list/placeholder_list.dart';
import 'custom_list/presence_list.dart';
import 'room_list_explore.dart';

class RoomList extends StatefulWidget {
  ///  [allowPop]
  const RoomList(
      {super.key,
      required this.client,
      required this.sortedRooms,
      required this.isMobile,
      this.onAppBarClicked,
      required this.controller});

  final ChatPageState controller;

  final Client client;
  final List<Room>? sortedRooms;
  final bool isMobile; // adapted for small screens
  final VoidCallback? onAppBarClicked;

  @override
  State<RoomList> createState() => _RoomListState();
}

class _RoomListState extends State<RoomList> {
  Function(String?) get onSelection => (String? roomId) {
        widget.controller.selectRoom(roomId);
      };

  String? get selectedRoomId => widget.controller.selectedRoomID;
  String get selectedSpace {
    final id = widget.controller.selectedSpace;
    return id != "" ? id : CustomSpacesTypes.home;
  }

  Set<String> selectedRooms = {};
  bool selectMode = false;

  static const double roomListSelectorHeight = 40;

  final scrollController =
      ScrollController(initialScrollOffset: roomListSelectorHeight);
  final spaceListScrollController = ScrollController();
  final scrollControllerDrawer = ScrollController();

  bool get isHome => selectedSpace == CustomSpacesTypes.home;

  void enableSelection() {
    if (!selectMode) {
      setState(() {
        selectMode = true;
      });
    }
  }

  void disableSelection() {
    setState(() {
      selectMode = false;
    });
    selectedRooms.clear();
  }

  void toggleElement(String roomId) {
    if (selectedRooms.contains(roomId)) {
      selectedRooms.remove(roomId);
      if (selectedRooms.isEmpty) selectMode = false;
    } else {
      selectedRooms.add(roomId);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    final isMobile = widget.isMobile;

    List<CachedPresence>? presences;

    if (selectedSpace == CustomSpacesTypes.active) {
      presences = client.presences.values.where((element) {
        if (client.getDirectChatFromUserId(element.userid) == null) {
          return false;
        }
        return element.currentlyActive == true;
      }).toList()
        ..sort((a, b) {
          if (a.lastActiveTimestamp != null && b.lastActiveTimestamp != null) {
            return b.lastActiveTimestamp!.compareTo(a.lastActiveTimestamp!);
          }
          return 0;
        });
    }
    final spaceRoom = client.getRoomById(selectedSpace);

    String title = selectedSpace;

    if (spaceRoom != null) {
      title = spaceRoom.getLocalizedDisplayname();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isHome
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => CreateChatPage(
                        client: client, onRoomSelected: onSelection)));
              },
              child: const Icon(Icons.message),
            )
          : null,
      appBar: selectMode == true
          ? AppBar(actions: [
              IconButton(
                  onPressed: disableSelection, icon: const Icon(Icons.close))
            ], automaticallyImplyLeading: false, title: const Text("Edit"))
          : AppBar(
              forceMaterialTransparency: true,
              title: Text(title),
              leading: AccountButton(
                client: client,
                onPressed: () async {
                  await context
                      .navigateTo(TabHomeRoute(children: [SettingsRoute()]));
                },
              ),
              actions: [
                if (isHome)
                  IconButton(
                      onPressed: () async {
                        final id =
                            await MatrixChatsSearch.show(context, client);
                        if (id != null) {
                          widget.controller.selectRoom(id);
                        }
                      },
                      icon: const Icon(Icons.search)),
                if (spaceRoom != null)
                  IconButton(
                      onPressed: () {
                        widget.controller.onLongPressedSpace(selectedSpace);
                      },
                      icon: const Icon(Icons.info))
              ],
            ),
      body: Column(
        children: [
          StreamBuilder<SyncStatusUpdate>(
              stream: client.onSyncStatus.stream,
              builder: (context, snap) {
                if (snap.hasData) {
                  if (snap.data!.status == SyncStatus.processing &&
                      ![null, 0, 1.0].contains(snap.data!.progress)) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child:
                          LinearProgressIndicator(value: snap.data!.progress!),
                    );
                  }
                }
                return Container();
              }),
          Expanded(
            child: selectedSpace == CustomSpacesTypes.explore
                ? RoomListExplore(
                    onSelect: (String roomId) {
                      widget.controller.selectRoom(roomId);
                    },
                  )
                : widget.controller.displaySpaceList
                    ? ChatPageSpaceList(
                        popAfterSelection: isMobile,
                        scrollController: spaceListScrollController,
                      )
                    : FutureBuilder(
                        future: client.roomsLoading, // Refresh the room
                        // list when client has finished loading.
                        builder: (context, snapshot) {
                          return CustomScrollView(
                            cacheExtent: 400,
                            physics: const AlwaysScrollableScrollPhysics(),
                            controller: scrollController,
                            slivers: [
                              // Room list selector
                              FilterBar(
                                roomListSelectorHeight: roomListSelectorHeight,
                                controller: widget.controller,
                              ),
                              if (presences != null)
                                PresenceList(
                                    presences: presences,
                                    client: client,
                                    onSelection: onSelection),
                              if (presences == null)
                                widget.sortedRooms != null
                                    ? widget.sortedRooms!.isEmpty
                                        ? NoRoomList()
                                        : SliverPadding(
                                            padding: const EdgeInsets.only(
                                                top: 8, bottom: 60),
                                            sliver: SliverList(
                                                delegate:
                                                    SliverChildBuilderDelegate(
                                                        (BuildContext context,
                                                            int i) {
                                              Room r = widget.sortedRooms![i];
                                              return RoomListItem(
                                                key: Key("room_${r.id}"),
                                                room: r,
                                                open: !isMobile &&
                                                    r.id == selectedRoomId,
                                                selected: selectedRooms
                                                    .contains(r.id),
                                                client: widget.client,
                                                onSelection: (String text) {
                                                  if (selectMode) {
                                                    toggleElement(r.id);
                                                  } else {
                                                    onSelection(text);
                                                  }
                                                },
                                                onLongPress: () {
                                                  selectedRooms.add(r.id);
                                                  enableSelection();
                                                },
                                              );
                                            },
                                                        childCount: widget
                                                            .sortedRooms!
                                                            .length)),
                                          )
                                    : PlaceholderList(),
                              SliverFillRemaining(),
                            ],
                          );
                        }),
          ),
        ],
      ),
    );
  }
}

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.roomListSelectorHeight,
    required this.controller,
  });

  final ChatPageState controller;
  final double roomListSelectorHeight;

  @override
  Widget build(BuildContext context) {
    return SliverFixedExtentList.builder(
      itemExtent: roomListSelectorHeight,
      itemBuilder: (BuildContext context, int i) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Center(
          child: Row(
            children: [
              CustomFilter(
                controller: controller,
                name: "All",
                spaceName: CustomSpacesTypes.home,
              ),
              CustomFilter(
                controller: controller,
                name: "Unreads",
                spaceName: CustomSpacesTypes.unread,
              ),
              CustomFilter(
                controller: controller,
                name: "Favorites",
                spaceName: CustomSpacesTypes.favorites,
              ),
              CustomFilter(
                controller: controller,
                name: "DMs",
                spaceName: CustomSpacesTypes.dm,
              ),
              CustomFilter(
                controller: controller,
                name: "Low priority",
                spaceName: CustomSpacesTypes.lowPriority,
              ),
            ],
          ),
        ),
      ),
      itemCount: 1,
    );
  }
}

class CustomFilter extends StatelessWidget {
  const CustomFilter({
    super.key,
    required this.controller,
    required this.name,
    required this.spaceName,
  });

  final ChatPageState controller;
  final String name;
  final String spaceName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(name),
        selected: controller.selectedSpace == spaceName,
        onSelected: (bool value) {
          controller.selectSpace(spaceName);
        },
      ),
    );
  }
}
