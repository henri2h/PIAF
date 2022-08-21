import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/layouts/customHeader.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

class SettingsAccountPage extends StatefulWidget {
  const SettingsAccountPage({Key? key}) : super(key: key);

  @override
  SettingsAccountPageState createState() => SettingsAccountPageState();
}

class SettingsAccountPageState extends State<SettingsAccountPage> {
  TextEditingController? displayNameController;
  bool savingDisplayName = false;

  @override
  Widget build(BuildContext context) {
    Client sclient = Matrix.of(context).client;
    final m = Matrix.of(context);

    return ListView(
      children: [
        const CustomHeader(title: "Account"),
        FutureBuilder(
            future: sclient.getUserProfile(sclient.userID!),
            builder: (context, AsyncSnapshot<ProfileInformation> p) {
              if (displayNameController == null && p.hasData == true) {
                displayNameController = TextEditingController(
                    text: (p.data?.displayname ?? sclient.userID!));
              }

              return ListTile(
                  leading: savingDisplayName
                      ? const CircularProgressIndicator()
                      : MatrixImageAvatar(
                          client: Matrix.of(context).client,
                          url: p.data?.avatarUrl,
                          width: 48,
                          height: 48,
                          defaultIcon: const Icon(Icons.person, size: 32),
                        ),
                  title: const Text("Edit display name"),
                  trailing: const Icon(Icons.edit),
                  subtitle: Text(p.data?.displayname ?? sclient.userID!),
                  onTap: () async {
                    List<String>? results = await showTextInputDialog(
                      context: context,
                      textFields: [
                        DialogTextField(
                            hintText: "Your display name",
                            initialText: p.data?.displayname ?? "")
                      ],
                      title: "Set display name",
                    );
                    if (results?.isNotEmpty == true) {
                      setState(() {
                        savingDisplayName = true;
                      });
                      await sclient.setDisplayName(
                          sclient.userID!, results![0]);
                      setState(() {
                        savingDisplayName = false;
                      });
                    }
                  });
            }),
        ListTile(
            title: const Text("Your user ID:"),
            subtitle: Text(sclient.userID ?? "null")),
      ],
    );
  }
}
