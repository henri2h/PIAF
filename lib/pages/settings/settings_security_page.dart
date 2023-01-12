import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'package:minestrix/partials/components/layouts/custom_header.dart';
import 'package:minestrix_chat/utils/matrix_sdk_extension/device_extensions.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import 'package:timeago/timeago.dart' as timeago;

import '../../partials/components/minestrix/minestrix_title.dart';

class SettingsSecurityPage extends StatefulWidget {
  const SettingsSecurityPage({Key? key}) : super(key: key);

  @override
  SettingsSecurityPageState createState() => SettingsSecurityPageState();
}

class SettingsSecurityPageState extends State<SettingsSecurityPage> {
  final TextEditingController _passphraseController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Client client = Matrix.of(context).client;

    return ListView(
      children: [
        const CustomHeader(title: "Security"),
        const H1Title("This session"),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                  leading: const Icon(Icons.title),
                  title: const Text("Device name"),
                  subtitle: Text(client.deviceName!)),
              ListTile(
                  leading: const Icon(Icons.perm_device_info),
                  title: const Text("Device id"),
                  subtitle: Text(client.deviceID!)),
            ],
          ),
        ),
        client.encryptionEnabled
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (client.encryption!.crossSigning.enabled == false)
                    const Text("❌ Cross signing is not enabled"),
                  ListTile(
                    leading: client.isUnknownSession == false
                        ? const Icon(Icons.check, size: 32, color: Colors.green)
                        : const Icon(Icons.error, size: 32),
                    title: const Text("Session status"),
                    subtitle: client.isUnknownSession == false
                        ? const Text("Verified")
                        : const Text(
                            "Not verified",
                          ),
                  ),
                  if (client.encryptionEnabled && client.isUnknownSession)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ElevatedButton(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: const [
                                Icon(Icons.enhanced_encryption),
                                SizedBox(width: 10),
                                Text("Setup encryption"),
                              ],
                            ),
                          ),
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (buildContext) => SimpleDialog(
                                      title: const Text("Setup encryption"),
                                      contentPadding: const EdgeInsets.all(20),
                                      children: [
                                        TextField(
                                            decoration: const InputDecoration(
                                                labelText: "Key Password"),
                                            controller: _passphraseController),
                                        const SizedBox(height: 15),
                                        ElevatedButton(
                                            child: const Text("Get keys"),
                                            onPressed: () async {
                                              await client
                                                  .encryption!.crossSigning
                                                  .selfSign(
                                                      passphrase:
                                                          _passphraseController
                                                              .text);
                                              _passphraseController.text = "";
                                            }),
                                      ],
                                    ));
                          }),
                    ),
                ],
              )
            : const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Encryption disabled ❌"),
              ),
        FutureBuilder<List<Device>?>(
            future: client.getDevices(),
            builder: (context, snap) {
              if (!snap.hasData) return Container();

              final devices = snap.data;

              devices!.sort(((a, b) {
                final da = a.lastSeenTs == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(a.lastSeenTs!);
                final db = b.lastSeenTs == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(b.lastSeenTs!);

                if (da == null || db == null) return 0;

                return db.compareTo(da);
              }));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const H1Title("Devices"),
                  for (final device in devices)
                    Builder(builder: (context) {
                      final dt = device.lastSeenTs != null
                          ? DateTime.fromMillisecondsSinceEpoch(
                              device.lastSeenTs!)
                          : null;

                      return ListTile(
                        leading: Icon(device.icon),
                        title: Text(device.displayname.toString()),
                        subtitle: Text(
                            "Last seen ${dt != null ? timeago.format(dt) : "some time ago"}"),
                      );
                    })
                ],
              );
            }),
      ],
    );
  }
}
