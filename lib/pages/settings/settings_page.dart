import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/layouts/customHeader.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

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
                  color: Theme.of(context).scaffoldBackgroundColor,
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

    return Column(
      children: [
        CustomHeader(title: "Settings", overrideCanPop: true),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ListView(
              children: [
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
                SettingsList(
                  lightTheme: SettingsThemeData(
                      settingsListBackground: Colors.transparent),
                  darkTheme: SettingsThemeData(
                      settingsListBackground: Colors.transparent),
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  sections: [
                    SettingsSection(
                      title: Text('Account'),
                      tiles: <SettingsTile>[
                        SettingsTile.navigation(
                          leading: Icon(Icons.person),
                          title: Text('Account'),
                          onPressed: (context) =>
                              context.navigateTo(SettingsAccountRoute()),
                        ),
                        SettingsTile.navigation(
                          leading: Icon(Icons.people),
                          description: Text("Organize your different profiles"),
                          title: Text('Profiles'),
                          onPressed: (context) =>
                              context.navigateTo(AccountsDetailsRoute()),
                        ),
                        SettingsTile.navigation(
                          leading: Icon(Icons.lock),
                          title: Text('Security'),
                          onPressed: (context) =>
                              context.navigateTo(SettingsSecurityRoute()),
                        ),
                      ],
                    ),
                    SettingsSection(
                      title: Text('Common'),
                      tiles: <SettingsTile>[
                        SettingsTile.navigation(
                          leading: Icon(Icons.format_paint),
                          title: Text('Theme'),
                          onPressed: (context) =>
                              context.navigateTo(SettingsThemeRoute()),
                        ),
                      ],
                    ),
                    SettingsSection(
                      title: Text('Danger'),
                      tiles: <SettingsTile>[
                        SettingsTile.navigation(
                          leading: Icon(Icons.warning),
                          title: Text('Labs'),
                          onPressed: (context) =>
                              context.navigateTo(SettingsLabsRoute()),
                        ),
                        SettingsTile.navigation(
                          leading: Icon(Icons.refresh),
                          title: Text('Sync'),
                          onPressed: (context) =>
                              context.navigateTo(SettingsSyncRoute()),
                        ),
                        SettingsTile.navigation(
                          leading: Icon(Icons.bug_report),
                          title: Text('Debug'),
                          onPressed: (context) =>
                              context.navigateTo(DebugRoute()),
                        ),
                        SettingsTile.navigation(
                            leading: Icon(Icons.logout, color: Colors.red),
                            title: Text('Logout'),
                            onPressed: (context) async {
                              final res = await showOkCancelAlertDialog(
                                  context: context,
                                  title: "Logout",
                                  message: "Are you sure ?",
                                  okLabel: "Yes");

                              if (res != OkCancelResult.ok) {
                                return;
                              }

                              await client.logout();
                              if (Navigator.of(context).canPop())
                                Navigator.of(context).pop();
                            }),
                      ],
                    ),
                    SettingsSection(
                      tiles: [
                        SettingsTile(
                          title: Text("About"),
                          description: FutureBuilder<PackageInfo>(
                              future: PackageInfo.fromPlatform(),
                              builder: (context, snap) {
                                if (!snap.hasData) return Container();
                                return Text("Version " +
                                    (snap.data?.version ?? 'null'));
                              }),
                        )
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
