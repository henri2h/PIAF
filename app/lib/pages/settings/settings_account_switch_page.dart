import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../../router.gr.dart';
import '../login_page.dart';

@RoutePage()
class SettingsAccountSwitchPage extends StatefulWidget {
  const SettingsAccountSwitchPage({Key? key, this.popOnUserSelected = false})
      : super(key: key);
  final bool popOnUserSelected;
  @override
  SettingsAccountSwitchPageState createState() =>
      SettingsAccountSwitchPageState();
}

class SettingsAccountSwitchPageState extends State<SettingsAccountSwitchPage> {
  TextEditingController? displayNameController;
  bool savingDisplayName = false;

  void addAccount() async {
    await AdaptativeDialogs.show(
        context: context,
        title: "Add an account",
        builder: (context) =>
            const LoginPage(popOnLogin: true, title: "Add a new account"));
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
          IconButton(onPressed: addAccount, icon: const Icon(Icons.add))
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
