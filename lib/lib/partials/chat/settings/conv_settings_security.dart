import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ConvSettingsSecurity extends StatefulWidget {
  const ConvSettingsSecurity({Key? key, required this.room}) : super(key: key);

  final Room room;

  @override
  State<ConvSettingsSecurity> createState() => _ConvSettingsSecurityState();
}

class _ConvSettingsSecurityState extends State<ConvSettingsSecurity> {
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

  @override
  Widget build(BuildContext context) {
    final room = widget.room;

    return StreamBuilder(
        stream: room.client.onSync.stream.where((event) => event.hasRoomUpdate),
        builder: (context, snapshot) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text("Security"),
              forceMaterialTransparency: true,
            ),
            body: ListView(
              children: [
                SwitchListTile(
                    value: room.encrypted,
                    onChanged: (bool value) async {
                      if (value) {
                        await room.enableEncryption();
                      }
                    },
                    title: const Text("Encryption"),
                    subtitle: const Text("Once enabled, cannot be disabled.")),
                const ListTile(
                  title: Text("Who can join?"),
                ),
                RadioListTile(
                    value: JoinRules.public,
                    groupValue: room.joinRules,
                    title: const Text("Anyone"),
                    subtitle: const Text("Anyone can find and join."),
                    onChanged: setJoinRules),
                RadioListTile(
                    value: JoinRules.invite,
                    groupValue: room.joinRules,
                    title: const Text("Invited"),
                    subtitle: const Text("Only invited can join."),
                    onChanged: setJoinRules),
                RadioListTile(
                    value: JoinRules.knock,
                    groupValue: room.joinRules,
                    title: const Text("Knock"),
                    subtitle: const Text("Anyone can ask to join the room."),
                    onChanged: setJoinRules),
                RadioListTile(
                    value: "restricted",
                    groupValue: room
                        .getState(EventTypes.RoomJoinRules)
                        ?.content['join_rule'],
                    title: const Text("Space members"),
                    subtitle:
                        const Text("Anyone in a space can find and join."),
                    onChanged: setRestricted),
                const ListTile(
                  title: Text("Who can read the history?"),
                ),
                if (room.joinRules == JoinRules.public)
                  RadioListTile(
                      value: HistoryVisibility.worldReadable,
                      groupValue: room.historyVisibility,
                      title: const Text("Anyone"),
                      onChanged: setHistoryVisibility),
                RadioListTile(
                    value: HistoryVisibility.shared,
                    groupValue: room.historyVisibility,
                    title: const Text(
                        "Members only (since selecting this option)"),
                    onChanged: setHistoryVisibility),
                RadioListTile(
                    value: HistoryVisibility.joined,
                    groupValue: room.historyVisibility,
                    title: const Text("Members only (since they joined)"),
                    onChanged: setHistoryVisibility),
                RadioListTile(
                    value: HistoryVisibility.invited,
                    groupValue: room.historyVisibility,
                    title:
                        const Text("Members only (since there were invited)"),
                    onChanged: setHistoryVisibility),
                SwitchListTile(
                    value: room.guestAccess == GuestAccess.canJoin,
                    onChanged: (value) async {
                      await room.setGuestAccess(
                          value ? GuestAccess.canJoin : GuestAccess.forbidden);
                    },
                    title: const Text("Guest access"),
                    subtitle: const Text("Can join?"))
              ],
            ),
          );
        });
  }
}
