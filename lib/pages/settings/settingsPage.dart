import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/pages/account/accountsDetailsPage.dart';
import 'package:minestrix/pages/debugPage.dart';
import 'package:minestrix/partials/components/layouts/customHeader.dart';
import 'package:minestrix/router.gr.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ListView(
        children: [
          CustomHeader("Settings"),
          ListTile(
            title: Text("Account"),
            trailing: Icon(Icons.arrow_forward),
            leading: Icon(Icons.person),
            onTap: () {
              context.navigateTo(SettingsAccountRoute());
            },
          ),
          ListTile(
            title: Text("Theme"),
            trailing: Icon(Icons.arrow_forward),
            leading: Icon(Icons.color_lens),
            onTap: () {
              context.navigateTo(SettingsThemeRoute());
            },
          ),
          ListTile(
            title: Text("Profiles"),
            trailing: Icon(Icons.arrow_forward),
            leading: Icon(Icons.people),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => Scaffold(body: AccountsDetailsPage())));
            },
          ),
          ListTile(
            title: Text("Security"),
            trailing: Icon(Icons.arrow_forward),
            leading: Icon(Icons.lock),
            onTap: () {
              context.navigateTo(SettingsSecurityRoute());
            },
          ),
          ListTile(
              title: Text("Labs"),
              trailing: Icon(Icons.arrow_forward),
              leading: Icon(Icons.warning),
              onTap: () {
                context.navigateTo(SettingsLabsRoute());
              }),
          ListTile(
            title: Text("Debug"),
            trailing: Icon(Icons.arrow_forward),
            leading: Icon(Icons.bug_report),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => Scaffold(body: DebugPage())));
            },
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: FutureBuilder<PackageInfo>(
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
