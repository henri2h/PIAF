import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'package:minestrix/partials/components/layouts/customHeader.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

class SettingsSecurityPage extends StatefulWidget {
  const SettingsSecurityPage({Key? key}) : super(key: key);

  @override
  _SettingsSecurityPageState createState() => _SettingsSecurityPageState();
}

class _SettingsSecurityPageState extends State<SettingsSecurityPage> {
  final TextEditingController _passphraseController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Client client = Matrix.of(context).client;

    return ListView(
      children: [
        CustomHeader(title: "Security"),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Device name : " + client.deviceName!),
              Text("Device ID : " + client.deviceID!),
            ],
          ),
        ),
        client.encryptionEnabled
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (client.encryption!.crossSigning.enabled == false)
                    Text("❌ Cross signing is not enabled"),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: client.isUnknownSession == false
                          ? [
                              Icon(Icons.check, size: 32),
                              SizedBox(width: 10),
                              Flexible(
                                  child: Text(
                                      "Verified session, you're good to go !!",
                                      style: TextStyle(fontSize: 18)))
                            ]
                          : [
                              Icon(Icons.error, size: 32),
                              SizedBox(width: 10),
                              Flexible(
                                  child: Text("Not verified session",
                                      style: TextStyle(fontSize: 18)))
                            ],
                    ),
                  ),
                  if (client.encryptionEnabled && client.isUnknownSession)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ElevatedButton(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
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
                                      title: Text("Setup encryption"),
                                      contentPadding: EdgeInsets.all(20),
                                      children: [
                                        TextField(
                                            decoration: InputDecoration(
                                                labelText: "Key Password"),
                                            controller: _passphraseController),
                                        SizedBox(height: 15),
                                        ElevatedButton(
                                            child: Text("Get keys"),
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
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Encryption disabled ❌"),
              ),
      ],
    );
  }
}
