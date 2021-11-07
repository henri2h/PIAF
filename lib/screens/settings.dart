import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/global/Managers/ThemeManager.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/screens/debugVue.dart';

import 'package:provider/provider.dart';

class SettingsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    final TextEditingController _passphraseController = TextEditingController();

    bool isDarkMode = context.read<ThemeNotifier>().isDarkMode();
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            H1Title("Settings"),
            Text("Logged in as " + sclient.userID),
            Text("Homeserver : " + sclient.homeserver.toString()),
            Text("Device name : " + sclient.deviceName),
            Text("Device ID : " + sclient.deviceID),
            SizedBox(height: 10),
            SwitchListTile(
                value: isDarkMode,
                secondary:
                    isDarkMode ? Icon(Icons.dark_mode) : Icon(Icons.light_mode),
                title:
                    isDarkMode ? Text("Set light mode") : Text("Set dark mode"),
                onChanged: (value) {
                  if (!value)
                    context.read<ThemeNotifier>().setLightMode();
                  else
                    context.read<ThemeNotifier>().setDarkMode();
                }),
            SizedBox(height: 10),
            MaterialButton(
                color: Colors.red,
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.white),
                      SizedBox(width: 10),
                      Text("logout", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                onPressed: () async {
                  await sclient.logout();
                  if (Navigator.of(context).canPop())
                    Navigator.of(context).pop();
                }),
            H2Title("Encryption"),
            sclient.encryptionEnabled
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Encryption enabled ✅"),
                      Text("Encryption.enabled : " +
                          sclient.encryption.enabled.toString()),
                      Text("Cross signing enabled : " +
                          sclient.encryption.crossSigning.enabled.toString()),
                      Text("Is unknown session : " +
                          sclient.isUnknownSession.toString()),
                      if (sclient.isUnknownSession == false)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Icon(Icons.check, size: 50),
                              SizedBox(width: 10),
                              Flexible(
                                  child: Text(
                                      "Verified session, you're good to go !!",
                                      style: TextStyle(fontSize: 20)))
                            ],
                          ),
                        ),
                      if (sclient.encryptionEnabled && sclient.isUnknownSession)
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
                                                controller:
                                                    _passphraseController),
                                            SizedBox(height: 15),
                                            ElevatedButton(
                                                child: Text("Get keys"),
                                                onPressed: () async {
                                                  await sclient
                                                      .encryption.crossSigning
                                                      .selfSign(
                                                          passphrase:
                                                              _passphraseController
                                                                  .text);
                                                  _passphraseController.text =
                                                      "";
                                                }),
                                          ],
                                        ));
                              }),
                        ),
                    ],
                  )
                : Text("Encryption disabled ❌"),
            H2Title("Debug"),
            ListTile(
              title: Text("Go to debug page"),
              trailing: Icon(Icons.arrow_forward),
              leading: Icon(Icons.bug_report),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => Scaffold(
                            appBar: AppBar(title: Text("Debug time !!")),
                            body: DebugView())));
              },
            ),
          ],
        ));
  }
}
