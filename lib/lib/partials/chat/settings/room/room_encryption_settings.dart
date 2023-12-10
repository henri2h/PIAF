import 'package:flutter/material.dart';

import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';

import 'package:minestrix_chat/utils/matrix_sdk_extension/device_extensions.dart';
import '../../../dialogs/key_verification_dialogs.dart';

class RoomUserDeviceKey extends StatefulWidget {
  final Room room;
  final String userId;
  const RoomUserDeviceKey(
      {super.key, required this.room, required this.userId});

  @override
  State<RoomUserDeviceKey> createState() => _RoomUserDeviceKeyState();
}

class _RoomUserDeviceKeyState extends State<RoomUserDeviceKey> {
  Future<void> onSelected(
      BuildContext context, String action, DeviceKeys key) async {
    switch (action) {
      case 'verify':
        final req = await key.startVerification();
        req.onUpdate = () {
          if (req.state == KeyVerificationState.done) {
            setState(() {});
          }
        };
        if (mounted) {
          await KeyVerificationDialog(request: req).show(context);
        }
        break;
      case 'verify_user':
        await verifyUser(key);
        break;
      case 'block':
        if (key.directVerified) {
          await key.setVerified(false);
        }
        await key.setBlocked(true);
        setState(() {});
        break;
      case 'unblock':
        setState(() {});
        break;
    }
  }

  Future<void> verifyUser(DeviceKeys key) async {
    final req = await widget.room.client.userDeviceKeys[key.userId]!
        .startVerification();
    req.onUpdate = () {
      if (req.state == KeyVerificationState.done) {
        setState(() {});
      }
    };
    if (mounted) await KeyVerificationDialog(request: req).show(context);
  }

  Future<List<DeviceKeys>> getKeys() async {
    return (await widget.room.getUserDeviceKeys())
        .where((element) => element.userId == widget.userId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: widget.room.onUpdate.stream,
        builder: (context, snapshot) {
          return FutureBuilder<List<DeviceKeys>>(
            future: getKeys(),
            builder: (BuildContext context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text("oopsSomethingWentWrong : ${snapshot.error}"),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2));
              }
              final deviceKeys = snapshot.data!;

              final userVerified = deviceKeys.isNotEmpty &&
                  widget.room.client.userDeviceKeys[deviceKeys[0].userId]!
                          .verified ==
                      UserVerifiedStatus.unknown;
              if (deviceKeys.isEmpty) {
                return const ListTile(
                  leading: Icon(Icons.list),
                  title: Text("No device keys found"),
                  subtitle: Text(
                      "We don't know any device associated with this user."),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: deviceKeys.length,
                itemBuilder: (BuildContext context, int i) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (i == 0 &&
                        widget.userId != widget.room.client.userID) ...{
                      const Divider(height: 1, thickness: 1),
                      ListTile(
                          title: Text(
                            widget.room
                                .getUserByMXIDSync(deviceKeys[i].userId)
                                .calcDisplayname(),
                          ),
                          subtitle: Text(
                              userVerified ? "User verified" : "Verify user"),
                          onTap: userVerified
                              ? null
                              : () => verifyUser(deviceKeys[0])),
                    },
                    PopupMenuButton(
                      onSelected: (dynamic action) =>
                          onSelected(context, action, deviceKeys[i]),
                      itemBuilder: (c) {
                        final items = <PopupMenuEntry<String>>[];
                        if (deviceKeys[i].blocked || !deviceKeys[i].verified) {
                          items.add(PopupMenuItem(
                            value: deviceKeys[i].userId ==
                                    widget.room.client.userID
                                ? 'verify'
                                : 'verify_user',
                            child: const Text("verifyStart"),
                          ));
                        }
                        if (deviceKeys[i].blocked) {
                          items.add(const PopupMenuItem(
                            value: 'unblock',
                            child: Text("unblockDevice"),
                          ));
                        }
                        if (!deviceKeys[i].blocked) {
                          items.add(const PopupMenuItem(
                            value: 'block',
                            child: Text("blockDevice"),
                          ));
                        }
                        return items;
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          foregroundColor: Colors.white,
                          backgroundColor: deviceKeys[i].color,
                          child: Icon(deviceKeys[i].icon),
                        ),
                        title: Text(
                          deviceKeys[i].displayname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              deviceKeys[i].deviceId!,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w300),
                            ),
                            const Spacer(),
                            Text(
                              deviceKeys[i].blocked
                                  ? "blocked"
                                  : deviceKeys[i].verified
                                      ? "verified"
                                      : "unverified",
                              style: TextStyle(
                                fontSize: 14,
                                color: deviceKeys[i].color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        });
  }
}

extension on DeviceKeys {
  Color get color => blocked
      ? Colors.red
      : verified
          ? Colors.green
          : Colors.orange;
}
