import 'dart:async';

import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/style/constants.dart';
import 'package:minestrix_chat/utils/client_information.dart';
import 'package:minestrix_chat/utils/text.dart';
import '../../dialogs/adaptative_dialogs.dart';
import 'matrix_chats_search_item.dart';

class MatrixChatsSearch extends StatefulWidget {
  const MatrixChatsSearch(
      {Key? key, required this.client, required this.c, required this.stream})
      : super(key: key);

  final TextEditingController c;
  final Client client;
  final Stream<String> stream;

  static Future<String?> show(BuildContext context, Client client) async {
    final c = TextEditingController();
    final s = StreamController<String>();

    FocusNode myfocus = FocusNode();
    Future.delayed(const Duration(seconds: 0), () {
      myfocus.requestFocus(); //auto focus on second text field.
    });

    String? roomId = await AdaptativeDialogs.show(
        context: context,
        title: "Search",
        subtitle: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: TextField(
              controller: c,
              onChanged: (data) {
                s.add(data);
              },
              focusNode: myfocus,
              autofocus: true,
              decoration: Constants.kTextFieldInputDecoration
                  .copyWith(hintText: "Search")),
        ),
        builder: (_) => MatrixChatsSearch(
            client: client, c: c, stream: s.stream) //ResearchView()
        );

    return roomId;
  }

  @override
  State<MatrixChatsSearch> createState() => _MatrixChatsSearchState();
}

class SearchItem {
  Room? room;
  Profile? profile;

  SearchItem({this.room, this.profile})
      : assert(room != null || profile != null);

  bool get isSpace => room?.isSpace ?? false;

  String get displayname =>
      room?.displayname ?? profile?.displayName ?? profile?.userId ?? '';
  Uri? get avatar => room?.avatar ?? profile?.avatarUrl;
  String get canonicalAlias => room?.canonicalAlias ?? '';
  String get topic => room?.topic ?? '';
  String get directChatMatrixID => room?.directChatMatrixID ?? '';
  bool get isDirectChat => room?.isDirectChat ?? false;

  bool get isProfile => profile != null;

  String get secondText => room != null
      ? (room!.isDirectChat
          ? room!.directChatMatrixID ?? ''
          : room!.topic.isNotEmpty
              ? room!.topic
              : room!.canonicalAlias)
      : profile?.userId ?? '';
}

class ResultList {
  final String searchText;
  final List<SearchItem> items;

  const ResultList(this.items, {this.searchText = ''});
}

class _MatrixChatsSearchState extends State<MatrixChatsSearch> {
  final roomsStream = StreamController<ResultList>();
  StreamSubscription? sub;

  bool peopleSearch = false;
  bool publicRoomSearch = false;

  Timer? _debounce;
  String? _lastQuery;
  void _onSearchChanged(String query) {
    _lastQuery = query;
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    searchRoom(
        widget.c.text
            .toLowerCase()
            .removeDiacritics()
            .removeSpecialCharacters(),
        remote: false);

    if (peopleSearch) {
      // In case of people search, we enable remote search
      _debounce = Timer(const Duration(milliseconds: 300), () {
        searchRoom(
            widget.c.text
                .toLowerCase()
                .removeDiacritics()
                .removeSpecialCharacters(),
            remote: true);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    roomsStream.add(ResultList(
        widget.client.rooms.map((e) => SearchItem(room: e)).toList()));

    sub = widget.stream.listen(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    sub?.cancel();
    super.dispose();
  }

  Future<Profile>? futureProfile;

  /// search in local and remote directory.
  Future<void> searchRoom(String name, {bool remote = false}) async {
    List<SearchItem> rooms = widget.client.rooms
        .where((r) =>
            !r.isExtinct &&
            (!peopleSearch || r.isDirectChat) &&
            (r.displayname
                    .toLowerCase()
                    .removeDiacritics()
                    .removeSpecialCharacters()
                    .contains(name) ||
                r.canonicalAlias.contains(name) ||
                r.id.contains(name)))
        .map((e) => SearchItem(room: e))
        .toList();

    roomsStream.add(ResultList(rooms, searchText: name));

    if (remote && peopleSearch) {
      // In case if the user has entered a valid userId in the search content,
      // we add it to the search result if the server returned the profile.
      if (widget.c.text.isValidMatrixId) {
        futureProfile = widget.client.getProfileFromUserId(widget.c.text);
      }

      try {
        SearchUserDirectoryResponse res =
            await widget.client.searchUserDirectory(name);

        rooms.addAll(res.results
            .where((user) => !rooms // just ignore already found users
                .any((element) => element.directChatMatrixID == user.userId))
            .map((p) => SearchItem(profile: p)));
      } catch (_) {}

      roomsStream.add(ResultList(rooms, searchText: name));
    }
  }

  void setSearchParameters({bool? publicRoomSearch, bool? peopleSearch}) {
    setState(() {
      this.publicRoomSearch = publicRoomSearch ?? this.publicRoomSearch;
      this.peopleSearch = peopleSearch ?? this.peopleSearch;
    });
    if (_lastQuery != null) searchRoom(_lastQuery!, remote: true);
  }

  @override
  Widget build(BuildContext context) {
    final lastOpened = widget.client.lastContacted();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: StreamBuilder<ResultList>(
          stream: roomsStream.stream,
          builder: (context, snapshot) {
            return ListView(
              children: [
                Row(
                  children: [
                    if (peopleSearch)
                      Chip(
                        label: const Text("People"),
                        avatar: const Icon(Icons.people),
                        onDeleted: () {
                          setSearchParameters(peopleSearch: false);
                        },
                      ),
                    if (publicRoomSearch)
                      Chip(
                        label: const Text("Public room"),
                        avatar: const Icon(Icons.public),
                        onDeleted: () {
                          setSearchParameters(publicRoomSearch: false);
                        },
                      ),
                  ],
                ),
                if (snapshot.data?.searchText.isNotEmpty != true)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Contacted recently"),
                      ),
                      FutureBuilder<List<String>>(
                          future: lastOpened,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final user in snapshot.data!)
                                    Builder(builder: (context) {
                                      final room =
                                          widget.client.getRoomById(user);
                                      final name = room?.getLocalizedDisplayname(
                                          const MatrixDefaultLocalizations());
                                      if (room != null) {
                                        return Card(
                                          child: InkWell(
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(12.0)),
                                            onTap: () {
                                              Navigator.pop(context, room.id);
                                            },
                                            child: SizedBox(
                                              width: 90,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  children: [
                                                    MatrixImageAvatar(
                                                      url: room.avatar,
                                                      client: room.client,
                                                      defaultText: name,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      name ?? "Room",
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      return Container();
                                    })
                                ],
                              ),
                            );
                          }),
                    ],
                  ),
                if (widget.c.text.isValidMatrixId)
                  FutureBuilder<Profile>(
                    future: futureProfile,
                    builder: (context, snap) => MaterialButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              MatrixImageAvatar(
                                  url: snap.data?.avatarUrl,
                                  client: widget.client),
                              const SizedBox(
                                width: 12,
                              ),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(snap.data?.displayName ??
                                        widget.c.text),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, widget.c.text)),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(snapshot.data?.searchText.isNotEmpty != true
                      ? "Suggestions"
                      : "Results"),
                ),
                if (snapshot.hasData)
                  for (SearchItem s in snapshot.data!.items)
                    MatrixChatsRoomSearchItem(search: s, client: widget.client),
                if (snapshot.data?.searchText.isNotEmpty == true &&
                    !publicRoomSearch &&
                    !peopleSearch)
                  Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.public),
                        title: const Text("Search public room"),
                        onTap: () {
                          setSearchParameters(publicRoomSearch: true);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.people),
                        title: const Text("Search people"),
                        onTap: () {
                          setSearchParameters(peopleSearch: true);
                        },
                      ),
                    ],
                  )
              ],
            );
          }),
    );
  }
}
