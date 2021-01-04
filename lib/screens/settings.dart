import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/global/smatrix.dart';

class SettingsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SClient client = Matrix.of(context).sclient;
    final TextEditingController _passphraseController = TextEditingController();
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            H1Title("Settings"),
            TextField(
                decoration: InputDecoration(labelText: "Key Password"),
                controller: _passphraseController),
            MaterialButton(
                child: Text("Get keys"),
                onPressed: () async {
                  await client.encryption.crossSigning
                      .selfSign(passphrase: _passphraseController.text);
                  _passphraseController.text = "";
                }),
            MaterialButton(
                child: Text("logout ?"),
                onPressed: () async {
                  await client.logout();
                })
          ],
        ));
  }
}
