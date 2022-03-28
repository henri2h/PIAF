import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';

import 'package:minestrix/partials/components/layouts/customHeader.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';

class SettingsAccountPage extends StatefulWidget {
  const SettingsAccountPage({Key? key}) : super(key: key);

  @override
  _SettingsAccountPageState createState() => _SettingsAccountPageState();
}

class _SettingsAccountPageState extends State<SettingsAccountPage> {
  TextEditingController? displayNameController;
  bool savingDisplayName = false;

  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;

    return ListView(
      children: [
        CustomHeader("Account"),
        ListTile(
            title: Text("Your user ID:"),
            subtitle: Text(sclient.userID ?? "null")),
        FutureBuilder(
            future: sclient.getUserProfile(sclient.userID!),
            builder: (context, AsyncSnapshot<ProfileInformation> p) {
              if (displayNameController == null && p.hasData == true) {
                displayNameController = new TextEditingController(
                    text: (p.data?.displayname ?? sclient.userID!));
              }

              return ListTile(
                  leading: savingDisplayName
                      ? CircularProgressIndicator()
                      : MatrixImageAvatar(
                          client: Matrix.of(context).sclient,
                          url: p.data?.avatarUrl,
                          width: 48,
                          height: 48,
                          thumnail: true,
                          defaultIcon: Icon(Icons.person, size: 32),
                        ),
                  title: Text("Edit display name"),
                  trailing: Icon(Icons.edit),
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
            iconColor: Colors.red,
            title: Text("Logout"),
            trailing: Icon(Icons.logout),
            onTap: () async {
              await sclient.logout();
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            }),
      ],
    );
  }
}
