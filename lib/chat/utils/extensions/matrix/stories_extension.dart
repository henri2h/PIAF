import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/chat/minestrix_chat.dart';
import 'package:minestrix/chat/partials/dialogs/adaptative_dialogs.dart';

import '../../../pages/matrix_storie_create.dart';

extension StoriesExtension on Client {
  static const String storiesRoomType = 'msc3588.stories.stories-room';
  static const String storiesBlockListType = 'msc3588.stories.block-list';

  static const int lifeTimeInHours = 24;
  static const int maxPostsPerStory = 20;

  /// Create a new stories room
  /// [waitForCreation] Indicate if the funtion must return only if the room has been added
  /// And setup encryption in that room
  Future<String> createStoryRoom(
      {bool waitForCreation = true,
      List<String>? invite,
      String? name,
      String? topic}) async {
    name = name?.trim();
    topic = topic?.trim();

    if (name?.isEmpty == true) name = null;
    if (topic?.isEmpty == true) topic = null;

    final p = await getProfileFromUserId(userID!);
    final id = await createRoom(
      creationContent: {"type": storiesRoomType},
      preset: CreateRoomPreset.privateChat,
      powerLevelContentOverride: {"events_default": 100},
      name: name ?? 'Stories from ${p.displayName}',
      topic: topic ??
          'This is a room for stories sharing, not unlike the similarly named features in other messaging networks. For best experience please use FluffyChat or MinesTRIX. Feature development can be followed on: https://github.com/matrix-org/matrix-doc/pull/3588',
      initialState: [
        if (encryptionEnabled)
          StateEvent(
            type: EventTypes.Encryption,
            stateKey: '',
            content: {
              'algorithm': 'm.megolm.v1.aes-sha2',
            },
          ),
        StateEvent(
          type: 'm.room.retention',
          stateKey: '',
          content: {
            'min_lifetime': 86400000,
            'max_lifetime': 86400000,
          },
        ),
      ],
      invite: invite,
    );

    if (getRoomById(id) == null && waitForCreation) {
      // Wait for room actually appears in sync
      await onSync.stream
          .firstWhere((sync) => sync.rooms?.join?.containsKey(id) ?? false);
    }

    return id;
  }

  Future<void> openStoryEditModalOrCreate(BuildContext context) async {
    List<Room> userStorieRooms = getStorieRoomsFromUser(userID: userID!);

    // if empty, we create the storie room
    if (userStorieRooms.isEmpty) {
      final result = await showOkCancelAlertDialog(
        useRootNavigator: false,
        context: context,
        title: "Create story room?",
        message:
            'Seems that you don\'t have a story room currently. Should we create one?',
      );
      if (result == OkCancelResult.ok) {
        await createStoryRoom(waitForCreation: true);
        userStorieRooms = getStorieRoomsFromUser(userID: userID!);
      }
    }

    if (context.mounted && userStorieRooms.isNotEmpty) {
      await AdaptativeDialogs.show(
          context: context,
          builder: (context) =>
              MatrixCreateStoriePage(client: this, r: userStorieRooms.first));
    }
  }

  /// Retrieve the list of users to ignore when creation stories
  List<String> getIgnoredUsersForStories() {
    return accountData[storiesBlockListType]
            ?.content
            .tryGet<List<dynamic>>("users")
            ?.map<String>((e) => e.toString())
            .toList() ??
        [];
  }

  /// Send the event to update the list of users to ignore when creating stories
  Future<void> setIgnoredUsers(List<String> users) async =>
      await setAccountData(userID!, storiesBlockListType, {"users": users});

  /// list all the room with the profile room type in m.room.create event
  List<Room> get storiesRooms =>
      rooms.where((room) => room.type == storiesRoomType).toList();

  /// list all the room with the profile room type in m.room.create event
  List<Room> get storiesRoomsSorted => storiesRooms.sorted;

  /// return all the storie rooms for a specific user
  List<Room> getStorieRoomsFromUser({required String userID}) =>
      storiesRooms.where((Room r) => r.creatorId == userID).toList().sorted;
}

extension on List<Room> {
  List<Room> get sorted => this
    ..sort((a, b) => a.lastEvent != null && b.lastEvent != null
        ? b.lastEvent!.originServerTs.compareTo(a.lastEvent!.originServerTs)
        : a.lastEvent != null
            ? -1
            : 1);
}
