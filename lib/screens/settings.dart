import 'package:flutter/material.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/global/smatrix.dart';

class SettingsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SClient client = Matrix.of(context).sclient;
    final TextEditingController _passphraseController = TextEditingController();
    return Scaffold(
        appBar: AppBar(title: Text("Settings")),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text("Hello you"),
              Text("hello"),
              TextField(
                  decoration: InputDecoration(labelText: "Password"),
                  controller: _passphraseController),
              MaterialButton(
                  child: Text("cross sign"),
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
          ),
        ));
  }
}
