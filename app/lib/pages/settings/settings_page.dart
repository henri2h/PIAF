import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

@RoutePage()
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

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
                constraints: const BoxConstraints(maxWidth: 360),
                child: const SettingsPanel(),
              ),
            const Expanded(child: AutoRouter())
          ],
        );
      }),
    );
  }
}

@RoutePage()
class SettingsPanelInnerPage extends StatelessWidget {
  const SettingsPanelInnerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (SettingsPage.of(context).smallScreen) return const SettingsPanel();
      return const Center(child: Icon(Icons.settings_accessibility, size: 80));
    });
  }
}

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.router.pop()),
        title: const Text("Settings"),
      ),
      body: FutureBuilder<TokenOwnerInfo>(
          future: client.getTokenOwner(),
          builder: (context, snapToken) {
            if (snapToken.hasData) {
              Matrix.of(context).setGuest(snapToken.data?.isGuest);
            }

            return ListView(
              children: [
                FutureBuilder(
                    future: client.getProfileFromUserId(client.userID!),
                    builder: (context, AsyncSnapshot<Profile> p) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            MatrixImageAvatar(
                              client: Matrix.of(context).client,
                              url: p.data?.avatarUrl,
                              width: 120,
                              height: 120,
                              defaultText: p.data?.displayName ?? client.userID,
                              defaultIcon: const Icon(Icons.person, size: 32),
                            ),
                            const SizedBox(height: 30),
                            Text(p.data?.displayName ?? client.userID!,
                                style: const TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.bold)),
                            if (snapToken.data?.isGuest == true)
                              const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20.0),
                                  child: ListTile(
                                    leading: Icon(Icons.explore,
                                        color: Colors.orange),
                                    title: Text("Guest account",
                                        style: TextStyle(color: Colors.orange)),
                                    subtitle: Text(
                                        "Guest interactions are limited",
                                        style: TextStyle(color: Colors.orange)),
                                  ))
                          ],
                        ),
                      );
                    }),
                SettingsList(
                  lightTheme: const SettingsThemeData(
                      settingsListBackground: Colors.transparent),
                  darkTheme: const SettingsThemeData(
                      settingsListBackground: Colors.transparent),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  sections: [
                    SettingsSection(
                      title: const Text('Account'),
                      tiles: <SettingsTile>[
                        SettingsTile.navigation(
                          leading: const Icon(Icons.person),
                          title: const Text('Account'),
                          onPressed: (context) =>
                              context.navigateTo(const SettingsAccountRoute()),
                        ),
                        SettingsTile.navigation(
                          leading: const Icon(Icons.list),
                          description:
                              const Text("Organize your different feeds"),
                          title: const Text('Feeds'),
                          onPressed: (context) =>
                              context.navigateTo(const AccountsDetailsRoute()),
                        ),
                        SettingsTile.navigation(
                          leading: const Icon(Icons.lock),
                          title: const Text('Security'),
                          onPressed: (context) =>
                              context.navigateTo(const SettingsSecurityRoute()),
                        ),
                        SettingsTile.navigation(
                          leading: const Icon(Icons.photo),
                          title: const Text('Story rooms'),
                          onPressed: (context) =>
                              context.navigateTo(const SettingsStorysRoute()),
                        ),
                      ],
                    ),
                    SettingsSection(
                      title: const Text('Multi account'),
                      tiles: <SettingsTile>[
                        SettingsTile.navigation(
                          leading: const Icon(Icons.switch_account),
                          title: const Text('Switch account'),
                          onPressed: (context) =>
                              context.navigateTo(SettingsAccountSwitchRoute()),
                        ),
                      ],
                    ),
                    SettingsSection(
                      title: const Text('Common'),
                      tiles: <SettingsTile>[
                        SettingsTile.navigation(
                          leading: const Icon(Icons.format_paint),
                          title: const Text('Theme'),
                          onPressed: (context) =>
                              context.navigateTo(const SettingsThemeRoute()),
                        ),
                      ],
                    ),
                    SettingsSection(
                      title: const Text('Danger'),
                      tiles: <SettingsTile>[
                        SettingsTile.navigation(
                          leading: const Icon(Icons.warning),
                          title: const Text('Labs'),
                          onPressed: (context) =>
                              context.navigateTo(const SettingsLabsRoute()),
                        ),
                        SettingsTile.navigation(
                          leading: const Icon(Icons.refresh),
                          title: const Text('Sync'),
                          onPressed: (context) =>
                              context.navigateTo(const SettingsSyncRoute()),
                        ),
                        SettingsTile.navigation(
                          leading: const Icon(Icons.bug_report),
                          title: const Text('Debug'),
                          onPressed: (context) =>
                              context.navigateTo(const DebugRoute()),
                        ),
                        SettingsTile.navigation(
                            leading:
                                const Icon(Icons.logout, color: Colors.red),
                            title: const Text('Sign out'),
                            onPressed: (context) async {
                              final res = await showOkCancelAlertDialog(
                                  context: context,
                                  title: "Sign out",
                                  message: "Are you sure ?",
                                  okLabel: "Yes");

                              if (res != OkCancelResult.ok) {
                                return;
                              }

                              await client.logout();
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            }),
                      ],
                    ),
                    SettingsSection(
                      tiles: [
                        SettingsTile(
                          title: const Text("About"),
                          description: FutureBuilder<PackageInfo>(
                              future: PackageInfo.fromPlatform(),
                              builder: (context, snap) {
                                if (!snap.hasData) return Container();
                                return Text(
                                    "Version ${snap.data?.version ?? 'null'}");
                              }),
                        )
                      ],
                    )
                  ],
                ),
              ],
            );
          }),
    );
  }
}
