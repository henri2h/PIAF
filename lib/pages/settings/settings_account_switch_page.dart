import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/pages/welcome/mobile/mobile_create_account_page.dart';
import 'package:minestrix/chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix/chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix/chat/utils/matrix_widget.dart';

import '../../router.gr.dart';
import '../welcome/mobile/mobile_login_page.dart';

@RoutePage()
class SettingsAccountSwitchPage extends StatefulWidget {
  const SettingsAccountSwitchPage({super.key, this.popOnUserSelected = false});
  final bool popOnUserSelected;
  @override
  SettingsAccountSwitchPageState createState() =>
      SettingsAccountSwitchPageState();
}

enum Selection {
  login,
  register,
}

class SettingsAccountSwitchPageState extends State<SettingsAccountSwitchPage> {
  TextEditingController? displayNameController;
  bool savingDisplayName = false;

  Future<void> login() async {
    await AdaptativeDialogs.show(
        context: context,
        title: "Login",
        builder: (context) => const MobileLoginPage());
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> register() async {
    await AdaptativeDialogs.show(
        context: context,
        title: "Register",
        builder: (context) => const MobileCreateAccountPage());
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = Matrix.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Switch account"),
        actions: [
          PopupMenuButton<Selection>(
              icon: const Icon(Icons.add),
              onSelected: (Selection selection) async {
                switch (selection) {
                  case Selection.register:
                    await register();
                    break;
                  case Selection.login:
                    await login();
                    break;
                }
              },
              itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: Selection.login,
                        child: ListTile(
                            leading: Icon(Icons.login),
                            title: Text('Login with an other account'))),
                    const PopupMenuItem(
                        value: Selection.register,
                        child: ListTile(
                            leading: Icon(Icons.add),
                            title: Text('Register a new account'))),
                  ]),
        ],
      ),
      body: ListView(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final c in m.widget.clients)
                ListTile(
                    title: Text(c.clientName),
                    leading: FutureBuilder<Profile>(
                        future: c.fetchOwnProfile(),
                        builder: (context, snap) {
                          return MatrixImageAvatar(
                            url: snap.data?.avatarUrl,
                            client: c,
                            defaultText: snap.data?.displayName,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                          );
                        }),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.userID ?? ''),
                      ],
                    ),
                    onTap: () async {
                      m.setActiveClient(c);
                      if (widget.popOnUserSelected) {
                        Navigator.of(context).pop();
                      } else {
                        context.navigateTo(const FeedRoute());
                      }
                    }),
            ],
          ),
        ],
      ),
    );
  }
}
