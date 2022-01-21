import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/pages/account/accountsDetailsPage.dart';
import 'package:minestrix/pages/debugPage.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/utils/Managers/ThemeManager.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController? displayNameController;
  bool savingDisplayName = false;

  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;
    final TextEditingController _passphraseController = TextEditingController();

    AppThemeMode? themeMode = context.read<ThemeNotifier>().mode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ListView(
        children: [
          H1Title("Settings"),
          H2Title("Profile"),
          FutureBuilder(
              future: sclient.getUserProfile(sclient.userID!),
              builder: (context, AsyncSnapshot<ProfileInformation> p) {
                if (displayNameController == null && p.hasData == true) {
                  displayNameController = new TextEditingController(
                      text: (p.data!.displayname ?? sclient.userID!));
                }

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (displayNameController != null)
                            SizedBox(
                              width: 200,
                              child: TextField(
                                controller: displayNameController,
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'User name',
                                    hintText: 'User name'),
                                onChanged: (_) {
                                  setState(() {});
                                },
                              ),
                            ),
                          SizedBox(width: 10),
                          if (displayNameController?.text !=
                              p.data?.displayname)
                            ElevatedButton(
                              child: SizedBox(
                                height: 50,
                                child: Row(
                                  children: [
                                    if (savingDisplayName)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10),
                                        child: CircularProgressIndicator(
                                            color: Colors.white),
                                      ),
                                    Text("Save"),
                                  ],
                                ),
                              ),
                              onPressed: () async {
                                if (displayNameController?.text !=
                                    null) if (savingDisplayName != true) {
                                  setState(() {
                                    savingDisplayName = true;
                                  });
                                  await sclient.setDisplayName(sclient.userID!,
                                      displayNameController?.text);
                                  setState(() {
                                    savingDisplayName = false;
                                  });
                                }
                              },
                            ),
                          SizedBox(width: 10),
                          MatrixUserImage(
                            client: Matrix.of(context).sclient,
                            url: p.data?.avatarUrl,
                            width: 48,
                            height: 48,
                            thumnail: true,
                            rounded: true,
                            defaultIcon: Icon(Icons.person, size: 32),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(sclient.userID!),
                      ),
                    ],
                  ),
                );
              }),
          ListTile(
            title: Text("Accounts"),
            trailing: Icon(Icons.arrow_forward),
            leading: Icon(Icons.people),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => Scaffold(
                          appBar: AppBar(title: Text("My accounts")),
                          body: AccountsDetailsPage())));
            },
          ),
          SizedBox(height: 10),
          SwitchListTile(
              value: themeMode == AppThemeMode.dark,
              secondary: themeMode == AppThemeMode.dark
                  ? Icon(Icons.dark_mode)
                  : Icon(Icons.light_mode),
              title: themeMode == AppThemeMode.dark
                  ? Text("Set light mode")
                  : Text("Set dark mode"),
              onChanged: (value) {
                if (!value)
                  context.read<ThemeNotifier>().setLightMode();
                else
                  context.read<ThemeNotifier>().setDarkMode();
                setState(() {});
              }),
          SizedBox(height: 10),
          H2Title("Security"),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Device name : " + sclient.deviceName!),
                Text("Device ID : " + sclient.deviceID!),
              ],
            ),
          ),
          sclient.encryptionEnabled
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sclient.encryption!.crossSigning.enabled == false)
                      Text("❌ Cross signing is not enabled"),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: sclient.isUnknownSession == false
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
                          body: DebugPage())));
            },
          ),
          H2Title("Danger zone"),
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
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              }),
          Padding(
            padding: const EdgeInsets.all(20),
            child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snap) {
                  if (!snap.hasData) return Container();
                  return Text("Version : " + (snap.data?.version ?? 'null'));
                }),
          ),
        ],
      ),
    );
  }
}
