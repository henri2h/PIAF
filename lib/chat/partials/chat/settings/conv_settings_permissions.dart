import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/chat/config/matrix_types.dart';

class ConvSettingsPermissions extends StatefulWidget {
  const ConvSettingsPermissions({super.key, required this.room});

  final Room room;

  @override
  State<ConvSettingsPermissions> createState() =>
      _ConvSettingsPermissionsState();
}

class _ConvSettingsPermissionsState extends State<ConvSettingsPermissions> {
  void setHistoryVisibility(HistoryVisibility? visibility) {
    if (visibility == null) return;
    widget.room.setHistoryVisibility(visibility);
  }

  void setJoinRules(JoinRules? rules) {
    if (rules == null) return;
    widget.room.setJoinRules(rules);
  }

  Future<void> setRestricted(value) async {
    if (value == null) return;
    final room = widget.room;
    await room.client.setRoomStateWithKey(
      room.id,
      EventTypes.RoomJoinRules,
      '',
      {
        'join_rule': 'restricted',
      },
    );
    return;
  }

  Map<String, dynamic>? permissions;
  Future<void> setPermision() async {
    if (permissions == null) return;
    final room = widget.room;
    await room.client.setRoomStateWithKey(
      room.id,
      EventTypes.RoomPowerLevels,
      '',
      permissions!,
    );
  }

  Icon getIconForPermission(String name) {
    switch (name) {
      case EventTypes.RoomName:
        return const Icon(Icons.title);
      case EventTypes.RoomAvatar:
        return const Icon(Icons.image);
      case EventTypes.RoomTopic:
        return const Icon(Icons.topic);
      case MatrixTypes.post:
        return const Icon(Icons.post_add);
      case MatrixTypes.comment:
        return const Icon(Icons.comment);
      case EventTypes.spaceChild:
        return const Icon(Icons.child_care);
      case EventTypes.Encryption:
        return const Icon(Icons.enhanced_encryption);
    }
    return const Icon(Icons.settings);
  }

  String getNameForPermission(String name) {
    switch (name) {
      case EventTypes.RoomName:
        return "Room name";
      case EventTypes.RoomAvatar:
        return "Room avatar";
      case EventTypes.RoomPowerLevels:
        return "Room power levels";
      case EventTypes.RoomTopic:
        return "Room topic";
      case MatrixTypes.post:
        return "Send post";
      case MatrixTypes.comment:
        return "Send comment";
      case EventTypes.spaceChild:
        return "Set space child";
      case EventTypes.Encryption:
        return "Activate encryption";
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;

    return StreamBuilder(
        stream: room.client.onSync.stream.where((event) => event.hasRoomUpdate),
        builder: (context, snapshot) {
          permissions = room.getState(EventTypes.RoomPowerLevels, "")?.content;
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text("Roles & permissions"),
              forceMaterialTransparency: true,
            ),
            body: permissions == null
                ? const Text("No premissions found")
                : ListView(
                    children: [
                      PermissionTile(
                        eventType: 'users_default',
                        icon: const Icon(Icons.power),
                        permissionName: 'Default user power levels',
                        room: room,
                        isEvent: false,
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("States permissions"),
                      ),
                      PermissionTile(
                        eventType: 'invite',
                        icon: const Icon(Icons.person_add),
                        permissionName: 'Can invinte',
                        room: room,
                        isEvent: false,
                      ),
                      PermissionTile(
                        eventType: 'kick',
                        icon: const Icon(Icons.person_remove),
                        permissionName: 'Can kick',
                        room: room,
                        isEvent: false,
                      ),
                      PermissionTile(
                        eventType: 'redact',
                        icon: const Icon(Icons.edit),
                        permissionName: 'Can redact',
                        room: room,
                        isEvent: false,
                      ),
                      PermissionTile(
                        eventType: 'historical',
                        icon: const Icon(Icons.history),
                        permissionName: 'Can edit history',
                        room: room,
                        isEvent: false,
                      ),
                      PermissionTile(
                        eventType: 'ban',
                        icon: const Icon(Icons.delete_forever),
                        permissionName: 'Can ban',
                        room: room,
                        isEvent: false,
                      ),
                      PermissionTile(
                        eventType: 'state_default',
                        icon: const Icon(Icons.title),
                        permissionName: 'Default send state permissions',
                        room: room,
                        isEvent: false,
                      ),
                      PermissionTile(
                        eventType: 'events_default',
                        icon: const Icon(Icons.message),
                        permissionName: 'Default send events permissions',
                        room: room,
                        isEvent: false,
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Events permissions"),
                      ),
                      for (var item
                          in permissions?.tryGetMap("events")?.keys ?? [])
                        PermissionTile(
                          eventType: item.toString(),
                          icon: getIconForPermission(item.toString()),
                          permissionName: getNameForPermission(item.toString()),
                          room: room,
                        ),
                      ListTile(
                          title: const Text("Room version"),
                          subtitle: Text(room
                                  .getState(EventTypes.RoomCreate)
                                  ?.content["room_version"]
                                  .toString() ??
                              '')),
                      ListTile(
                          title: const Text("Room creator"),
                          subtitle: Text(room
                                  .getState(EventTypes.RoomCreate)
                                  ?.senderFromMemoryOrFallback
                                  .calcDisplayname() ??
                              '')),
                      if (room
                              .getState(EventTypes.RoomCreate)
                              ?.content["type"] !=
                          null)
                        ListTile(
                            title: const Text("Room type"),
                            subtitle: Text(room
                                    .getState(EventTypes.RoomCreate)
                                    ?.content["type"]
                                    .toString() ??
                                ''))
                    ],
                  ),
          );
        });
  }
}

class PermissionTile extends StatelessWidget {
  const PermissionTile(
      {super.key,
      required this.room,
      required this.icon,
      required this.permissionName,
      this.permissionComment,
      required this.eventType,
      this.isEvent = true});

  final Room room;
  final Icon icon;
  final String permissionName;
  final String? permissionComment;
  final String eventType;
  final bool isEvent;

  void setValue(int? value) async {
    if (value == null) return;

    final permissions = room.getState(EventTypes.RoomPowerLevels, "")?.content;
    if (permissions != null &&
        (!isEvent || permissions["events"] is Map<String, dynamic>)) {
      if (isEvent) {
        final permissionsEventsMap =
            permissions["events"] as Map<String, dynamic>;
        permissionsEventsMap[eventType] = value;
      } else {
        permissions[eventType] = value;
      }
      await room.client
          .setRoomStateWithKey(room.id, "m.room.power_levels", "", permissions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = room.getState(EventTypes.RoomPowerLevels, "")?.content;
    final eventsPermissions = permissions?.tryGetMap<String, dynamic>("events");
    final eventPermission =
        (isEvent ? eventsPermissions : permissions)?.tryGet<int>(eventType) ??
            permissions?.tryGet<int>("events_default");

    return ExpansionTile(
      title: Text(permissionName),
      leading: icon,
      subtitle: Text(permissionComment ?? '$eventPermission'),
      trailing: const Icon(Icons.edit),
      children: [
        RadioListTile(
            toggleable: room.canChangePowerLevel,
            value: 0,
            groupValue: eventPermission,
            onChanged: setValue,
            secondary: const Icon(Icons.group),
            title: const Text("Anyone")),
        RadioListTile(
            toggleable: room.canChangePowerLevel,
            value: 50,
            groupValue: eventPermission,
            onChanged: setValue,
            secondary: const Icon(Icons.add_moderator),
            title: const Text("Moderator")),
        RadioListTile(
            toggleable: room.canChangePowerLevel,
            value: 100,
            groupValue: eventPermission,
            secondary: const Icon(Icons.person),
            onChanged: setValue,
            title: const Text("Admin"))
      ],
    );
  }
}
