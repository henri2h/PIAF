import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/layouts/custom_header.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/partials/dialogs/key_verification_dialogs.dart';
import 'package:minestrix_chat/utils/matrix_sdk_extension/device_extensions.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../partials/components/minestrix/minestrix_title.dart';

class SettingsSecurityPage extends StatefulWidget {
  const SettingsSecurityPage({Key? key}) : super(key: key);

  @override
  SettingsSecurityPageState createState() => SettingsSecurityPageState();
}

class SettingsSecurityPageState extends State<SettingsSecurityPage> {
  final TextEditingController _passphraseController = TextEditingController();
  Future<void> unlockCrossSigning() async {
    final client = Matrix.of(context).client;
    await showDialog(
        context: context,
        builder: (buildContext) => SimpleDialog(
              title: const Text("Setup encryption"),
              contentPadding: const EdgeInsets.all(20),
              children: [
                TextField(
                    decoration:
                        const InputDecoration(labelText: "Key Password"),
                    controller: _passphraseController),
                const SizedBox(height: 15),
                ElevatedButton(
                    child: const Text("Get keys"),
                    onPressed: () async {
                      await client.encryption!.crossSigning
                          .selfSign(passphrase: _passphraseController.text);
                      _passphraseController.text = "";
                    }),
              ],
            ));
  }

  static void renameDevice(BuildContext context, String deviceId,
      {String? deviceName}) async {
    final client = Matrix.of(context).client;
    final result = await showTextInputDialog(context: context, textFields: [
      DialogTextField(hintText: "New name", initialText: deviceName),
    ]);

    if (result?.isNotEmpty == true && result?.first.isNotEmpty == true) {
      await context.showFutureInTryCatch(
          () => client.updateDevice(deviceId!, displayName: result!.first));
    }
  }

  Future<void> deleteAllOldSessions(BuildContext context) async {
    final client = Matrix.of(context).client;

    List<DeviceKeys> devices = client.userID != null
        ? client.userDeviceKeys[client.userID]?.deviceKeys.values
                .where((deviceKey) => !deviceKey.blocked)
                .toList() ??
            []
        : [];

    devices.removeWhere((device) {
      final difference = DateTime.now().difference(device.lastActive).inDays;
      return difference < 90;
    });

    final devicesList = devices
        .where((element) => element.deviceId != null)
        .map((e) => e.deviceId!)
        .toList();
    if (devicesList.isEmpty) {
      await showOkAlertDialog(
          context: context, message: "No sessions to remove");

      return;
    }

    final result = await showOkCancelAlertDialog(
        context: context,
        title: "${devicesList.length} sessions are going to be deleted",
        message:
            "Are you sure you want to delete this device? This operation cannot be undone.");
    if (result != OkCancelResult.ok) {
      return;
    }

    final auth = await client.getAuthData(context);
    if (auth != null) {
      await context.showFutureInTryCatch(
          () async => client.deleteDevices(devicesList, auth: auth));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Client client = Matrix.of(context).client;

    List<DeviceKeys> verifiedDevices = client.userID != null
        ? client.userDeviceKeys[client.userID]?.deviceKeys.values
                .where((deviceKey) => deviceKey.verified && !deviceKey.blocked)
                .toList() ??
            []
        : [];

    return ListView(
      children: [
        const CustomHeader(title: "Security"),
        FutureBuilder<List<Device>?>(
            future: client.getDevices(),
            builder: (context, snap) {
              return StreamBuilder<Object>(
                  stream: client.onSync.stream,
                  builder: (context, snapshot) {
                    // update last seen time
                    if (snap.hasData) {
                      for (final device in snap.data!) {
                        if (device.lastSeenTs != null &&
                            client.userDeviceKeys[client.userID]?.deviceKeys
                                    .containsKey(device.deviceId) ==
                                true) {
                          final deviceFromClient = client
                              .userDeviceKeys[client.userID]
                              ?.deviceKeys[device.deviceId];

                          deviceFromClient?.lastActive =
                              DateTime.fromMillisecondsSinceEpoch(
                                  device.lastSeenTs!);
                        }
                      }
                    }

                    // sort devices list

                    verifiedDevices
                        .sort((a, b) => b.lastActive.compareTo(a.lastActive));

                    final unverifiedDevices = client.unverifiedDevices
                      ..sort((a, b) => b.lastActive.compareTo(a.lastActive));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SettingsList(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            lightTheme: const SettingsThemeData(
                                settingsListBackground: Colors.transparent),
                            darkTheme: const SettingsThemeData(
                                settingsListBackground: Colors.transparent),
                            sections: [
                              SettingsSection(
                                  title: const Text("This session"),
                                  tiles: [
                                    SettingsTile(
                                      leading: const Icon(Icons.title),
                                      title: const Text("Device name"),
                                      value: Text(client.deviceName ?? ""),
                                      trailing: const Icon(Icons.edit),
                                      onPressed: (context) => renameDevice(
                                          context, client.deviceID!,
                                          deviceName: client.deviceName),
                                    ),
                                    SettingsTile(
                                        leading:
                                            const Icon(Icons.perm_device_info),
                                        title: const Text("Device id"),
                                        value: Text(client.deviceID!)),
                                  ]),
                              SettingsSection(
                                tiles: [
                                  if (client.encryptionEnabled)
                                    if (client
                                            .encryption!.crossSigning.enabled ==
                                        false)
                                      SettingsTile(
                                          title: const Text(
                                              "❌ Cross signing is not enabled")),
                                  SettingsTile(
                                    leading: client.isUnknownSession == false
                                        ? const Icon(Icons.check,
                                            size: 32, color: Colors.green)
                                        : const Icon(Icons.error, size: 32),
                                    title: const Text("Session status"),
                                    value: client.isUnknownSession == false
                                        ? const Text("Verified")
                                        : const Text(
                                            "Not verified",
                                          ),
                                  ),
                                  if (client.encryptionEnabled)
                                    if (client.encryptionEnabled &&
                                        client.isUnknownSession)
                                      SettingsTile(
                                        onPressed: (context) =>
                                            unlockCrossSigning(),
                                        leading: const Icon(
                                            Icons.enhanced_encryption),
                                        title: const Text("Setup encryption"),
                                      ),
                                  if (!client.encryptionEnabled)
                                    SettingsTile(
                                        title: const Text(
                                            "Encryption disabled ❌")),
                                ],
                              ),
                              SettingsSection(
                                  title: const Text("Unverified devices"),
                                  tiles: [
                                    for (final device in unverifiedDevices)
                                      buildDeviceWidgetTile(device),
                                  ]),
                              SettingsSection(
                                  title: const Text("Verified devices"),
                                  tiles: <SettingsTile>[
                                    for (final device in verifiedDevices)
                                      buildDeviceWidgetTile(device),
                                  ]),
                              SettingsSection(
                                  title: const Text("This session"),
                                  tiles: [
                                    SettingsTile(
                                      onPressed: deleteAllOldSessions,
                                      leading: const Icon(Icons.delete_forever,
                                          color: Colors.red),
                                      title:
                                          const Text("Remove all old sessions"),
                                      description: const Text(
                                          "Remove all sessions older than 90 days old"),
                                    ),
                                  ])
                            ]),
                      ],
                    );
                  });
            }),
      ],
    );
  }

  SettingsTile buildDeviceWidgetTile(DeviceKeys device) {
    return SettingsTile(
        onPressed: (context) async {
          await DeviceWidget.show(context, device);
          setState(() {});
        },
        leading: Icon(device.icon, color: device.verified ? null : Colors.red),
        title: Text(
          device.displayname,
        ),
        trailing: device.verified
            ? const Icon(Icons.verified_user, color: Colors.green)
            : const Icon(
                Icons.gpp_bad,
                color: Colors.red,
              ),
        value: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "${device.verified ? "Verified" : "Unverified"} - Last activity ${timeago.format(device.lastActive)} - ${device.identifier}")
          ],
        ));
  }
}

class DeviceWidget extends StatelessWidget {
  const DeviceWidget({
    Key? key,
    required this.device,
  }) : super(key: key);

  static Future<void> show(BuildContext context, DeviceKeys device) async {
    await AdaptativeDialogs.show(
        builder: (context) {
          return DeviceWidget(device: device);
        },
        context: context);
  }

  final DeviceKeys device;

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;

    return FutureBuilder<Device>(
        future:
            device.deviceId == null ? null : client.getDevice(device.deviceId!),
        builder: (context, snapshot) {
          final deviceFromServer = snapshot.data;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                H1Title(deviceFromServer?.displayName ?? device.displayname),
                Card(
                  child: ListTile(
                    title: const Text("Verification status"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(device.verified ? "Verified" : "Unverified"),
                        if (!device.verified)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: MaterialButton(
                              color: Colors.green,
                              onPressed: () async {
                                final req = device.startVerification();

                                await KeyVerificationDialog(request: req)
                                    .show(context);
                              },
                              child: const SizedBox(
                                  width: 140,
                                  height: 40,
                                  child: Center(
                                    child: Text("Verify session"),
                                  )),
                            ),
                          )
                      ],
                    ),
                    leading: device.verified
                        ? const Icon(Icons.verified_user, color: Colors.green)
                        : const Icon(
                            Icons.gpp_bad,
                            color: Colors.red,
                          ),
                  ),
                ),
                ListTile(
                    title: const Text("Rename session"),
                    subtitle: Text(device.displayname),
                    trailing: const Icon(Icons.edit),
                    leading: const Icon(Icons.title),
                    onTap: () => SettingsSecurityPageState.renameDevice(
                        context, device.deviceId!,
                        deviceName: device.displayname)),
                ListTile(
                    title: const Text("Device identifier"),
                    leading: const Icon(Icons.numbers),
                    subtitle: Text("${device.identifier}")),
                Builder(builder: (context) {
                  final date = deviceFromServer?.lastSeenTs != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                          deviceFromServer!.lastSeenTs!)
                      : device.lastActive;
                  return ListTile(
                      title: const Text("Last activity"),
                      leading: const Icon(Icons.date_range),
                      subtitle: Text(
                          "${timeago.format(date)} - ${DateFormat.yMMMMEEEEd().format(date)} - ${DateFormat.jms().format(date)}"));
                }),
                if (deviceFromServer?.lastSeenIp != null)
                  ListTile(
                      leading: const Icon(Icons.http),
                      title: const Text("Last seen ip"),
                      subtitle: Text(deviceFromServer!.lastSeenIp!)),
                ListTile(
                    onTap: () async {
                      final result = await showOkCancelAlertDialog(
                          context: context,
                          title: "Delete this device",
                          message:
                              "Are you sure you want to delete this device? This operation cannot be undone.");
                      if (result != OkCancelResult.ok ||
                          device.deviceId == null) {
                        return;
                      }

                      final auth = await client.getAuthData(context);
                      if (auth != null) {
                        final result =
                            await context.showFutureInTryCatch(() async {
                          await client.deleteDevice(device.deviceId!,
                              auth: auth);
                          return true;
                        });
                        if (result == true) Navigator.of(context).pop();
                      }
                    },
                    title: const Text("Delete device"),
                    leading:
                        const Icon(Icons.delete_forever, color: Colors.red))
              ],
            ),
          );
        });
  }
}

extension DialogAuth on Client {
  Future<AuthenticationData?> getAuthData(BuildContext context) async {
    final result = await showTextInputDialog(context: context, textFields: [
      const DialogTextField(
          hintText: "New password", initialText: "", obscureText: true),
    ]);

    if (result?.isNotEmpty == true && result?.first.isNotEmpty == true) {
      final identifier =
          AuthenticationUserIdentifier(user: Matrix.of(context).client.userID!);
      return AuthenticationPassword(
          password: result!.first, identifier: identifier);
    }
    return null;
  }
}

extension on BuildContext {
  Future<T?> showFutureDialog<T>(Future<T> future) async {
    return await showDialog(
        context: this,
        builder: (context) {
          future.then((val) {
            Navigator.of(context).pop(val);
          });

          return FutureBuilder(
              future: future,
              builder: (context, snapshot) {
                return Dialog(
                    child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Builder(builder: (context) {
                    if (snapshot.hasError) {
                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text("Something bad happened!"),
                              subtitle: Text(snapshot.error.toString()),
                            ),
                            TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text("Ok"))
                          ],
                        ),
                      );
                    }

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(
                          width: 10,
                        ),
                        Text("Loading...")
                      ],
                    );
                  }),
                ));
              });
        });
  }

  Future<T?> showFutureInTryCatch<T>(Future<T> Function() function) async {
    try {
      final result = function();
      return await showFutureDialog(result);
    } catch (ex) {
      if (mounted) {
        await showOkAlertDialog(
            context: this,
            title: "Something unexpected happened",
            message: ex.toString());
      } else {
        print(ex);
      }
    }
  }
}
