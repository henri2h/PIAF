import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/layouts/custom_header.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../../router.gr.dart';
import '../login_page.dart';

class SettingsAccountSwitchPage extends StatefulWidget {
  const SettingsAccountSwitchPage({Key? key}) : super(key: key);

  @override
  SettingsAccountSwitchPageState createState() =>
      SettingsAccountSwitchPageState();
}

class SettingsAccountSwitchPageState extends State<SettingsAccountSwitchPage> {
  TextEditingController? displayNameController;
  bool savingDisplayName = false;

  @override
  Widget build(BuildContext context) {
    final m = Matrix.of(context);

    return ListView(
      children: [
        const CustomHeader(title: "Switch account"),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
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
                            backgroundColor: Theme.of(context).primaryColor,
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
                      context.navigateTo(const FeedRoute());
                    }),
              ListTile(
                  title: const Text("Add an account"),
                  trailing: const Icon(Icons.add),
                  onTap: () async {
                    await AdaptativeDialogs.show(
                        context: context,
                        bottomSheet: true,
                        builder: (context) => LoginPage(
                            popOnLogin: true, title: "Add a new account"));
                    if (mounted) {
                      setState(() {});
                    }
                  }),
            ],
          ),
        ),
      ],
    );
  }
}
