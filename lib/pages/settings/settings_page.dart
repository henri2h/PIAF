import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/layouts/customHeader.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  static SettingsPageState of(BuildContext context) =>
      Provider.of<SettingsPageState>(context, listen: false);
  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  bool smallScreen = false;
  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => this,
      child: LayoutBuilder(builder: (context, constraints) {
        smallScreen = constraints.maxWidth < 800;
        return Row(
          children: [
            if (!smallScreen)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 360),
                child: Container(
                  color: Theme.of(context).cardColor,
                  child: SettingsPanel(),
                ),
              ),
            Expanded(child: AutoRouter())
          ],
        );
      }),
    );
  }
}

class SettingsPanelInnerPage extends StatelessWidget {
  const SettingsPanelInnerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (SettingsPage.of(context).smallScreen) return SettingsPanel();
      return Center(child: Icon(Icons.settings_accessibility, size: 80));
    });
  }
}

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ListView(
        children: [
          CustomHeader(title: "Settings", overrideCanPop: true),
          FutureBuilder(
              future: client.getUserProfile(client.userID!),
              builder: (context, AsyncSnapshot<ProfileInformation> p) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      MatrixImageAvatar(
                        client: Matrix.of(context).client,
                        url: p.data?.avatarUrl,
                        width: 120,
                        height: 120,
                        thumnail: true,
                        defaultText: p.data?.displayname ?? client.userID,
                        defaultIcon: Icon(Icons.person, size: 32),
                      ),
                      SizedBox(height: 30),
                      Text(p.data?.displayname ?? client.userID!,
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
          SizedBox(height: 20),
          ListTile(
            title: Text("Account"),
            subtitle: Text("Change display name..."),
            leading: Icon(Icons.person),
            onTap: () {
              context.navigateTo(SettingsAccountRoute());
            },
          ),
          ListTile(
            title: Text("Theme"),
            subtitle: Text("Customize the app"),
            leading: Icon(Icons.color_lens),
            onTap: () {
              context.navigateTo(SettingsThemeRoute());
            },
          ),
          ListTile(
            title: Text("Profiles"),
            subtitle: Text("Control your profiles"),
            leading: Icon(Icons.people),
            onTap: () {
              context.navigateTo(AccountsDetailsRoute());
            },
          ),
          ListTile(
            title: Text("Security"),
            subtitle: Text("Encryption, verify your devices..."),
            leading: Icon(Icons.lock),
            onTap: () {
              context.navigateTo(SettingsSecurityRoute());
            },
          ),
          ListTile(
              title: Text("Labs"),
              subtitle: Text("Experimental features, use with caution"),
              leading: Icon(Icons.warning),
              onTap: () {
                context.navigateTo(SettingsLabsRoute());
              }),
          ListTile(
            title: Text("Debug"),
            subtitle: Text("Oups, something went wrong ?"),
            leading: Icon(Icons.bug_report),
            onTap: () {
              context.navigateTo(DebugRoute());
            },
          ),
          SizedBox(height: 40),
          ListTile(
              iconColor: Colors.red,
              title: Text("Logout"),
              trailing: Icon(Icons.logout),
              onTap: () async {
                await client.logout();
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              }),
          ListTile(
            title: Text("About"),
            subtitle: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snap) {
                  if (!snap.hasData) return Container();
                  return Text("Version " + (snap.data?.version ?? 'null'));
                }),
          ),
        ],
      ),
    );
  }
}
