import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/global/smatrix.dart';

class SettingsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
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
                  await sclient.encryption.crossSigning
                      .selfSign(passphrase: _passphraseController.text);
                  _passphraseController.text = "";
                }),
            MaterialButton(
                child: Text("logout ?"),
                onPressed: () async {
                  await sclient.logout();
                }),
                H2Title("Encryption"),
                sclient.encryptionEnabled ? Column(
                  children: [
                    Text("Encrytpion enabled ✅"),

                    Text("Encryption.enabled : " + sclient.encryption.enabled.toString()),
                    Text("Cross signing enabled : " + sclient.encryption.crossSigning.enabled.toString()),
                    Text("Unknown session : " + sclient.isUnknownSession.toString()),

                    if(sclient.isUnknownSession == false) Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(Icons.check, size:50),
                          SizedBox(width:10),
                          Flexible(child: Text("Verified session, you're good to go !!", style:TextStyle(fontSize: 20)))
                        ],
                      ),
                    )
                  ],
                ) : Text("Encrytpion disabled ❌"),
                
          ],
        ));
  }
}
