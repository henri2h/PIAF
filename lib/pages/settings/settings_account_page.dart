import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/layouts/custom_header.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsAccountPage extends StatefulWidget {
  const SettingsAccountPage({Key? key}) : super(key: key);

  @override
  SettingsAccountPageState createState() => SettingsAccountPageState();
}

class SettingsAccountPageState extends State<SettingsAccountPage> {
  TextEditingController? displayNameController;
  bool savingDisplayName = false;
  bool uploadingFile = false;

  void setDisplayName(AsyncSnapshot<ProfileInformation> p) async {
    final client = Matrix.of(context).client;
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
      await client.setDisplayName(client.userID!, results![0]);
      setState(() {
        savingDisplayName = false;
      });
    }
  }

  void changePassword() async {
    List<String>? results = await showTextInputDialog(
      context: context,
      textFields: const [
        DialogTextField(
            hintText: "Old password", initialText: "", obscureText: true),
        DialogTextField(
            hintText: "New password", initialText: "", obscureText: true),
        DialogTextField(
            hintText: "Re type your new password",
            initialText: "",
            obscureText: true)
      ],
      title: "Change password",
    );
    if (results?.isNotEmpty == true) {
      if (results![1] != results[2]) {
        await showOkAlertDialog(
          context: context,
          title: "Passwords don't match",
          message: "Make sure to enter the same password twice.",
        );
      } else {
        try {
          await Matrix.of(context)
              .client
              .changePassword(results[0], oldPassword: results[1]);
        } catch (ex) {
          await showAlertDialog(
              context: context,
              title: "Something unexpected happened",
              message: ex.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Client client = Matrix.of(context).client;
    return ListView(
      children: [
        const CustomHeader(title: "Account"),
        FutureBuilder(
            future: client.getUserProfile(client.userID!),
            builder: (context, AsyncSnapshot<ProfileInformation> p) {
              return SettingsList(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  sections: [
                    SettingsSection(
                        title: const Text("Avatar"),
                        tiles: <SettingsTile>[
                          SettingsTile.navigation(
                            leading: uploadingFile
                                ? const CircularProgressIndicator()
                                : MatrixImageAvatar(
                                    client: Matrix.of(context).client,
                                    url: p.data?.avatarUrl,
                                    width: 48,
                                    height: 48,
                                    defaultIcon:
                                        const Icon(Icons.person, size: 32),
                                  ),
                            title: const Text("Set Avatar"),
                            trailing: const Icon(Icons.edit),
                            onPressed: (context) async {
                              FilePickerResult? result =
                                  await FilePicker.platform.pickFiles(
                                      type: FileType.image, withData: true);

                              if (result?.files.first.bytes == null) return;

                              setState(() {
                                uploadingFile = true;
                              });

                              await client.setAvatar(MatrixFile(
                                  bytes: result!.files.first.bytes!,
                                  name: result.files.first.name));

                              setState(() {
                                uploadingFile = false;
                              });
                            },
                          ),
                          if (p.data?.avatarUrl != null)
                            SettingsTile.navigation(
                              title: const Text("Remove Avatar"),
                              trailing: const Icon(Icons.delete_forever),
                              onPressed: (context) async {
                                final res = await showOkCancelAlertDialog(
                                    context: context,
                                    title: "Remove avatar image",
                                    message: "Are you sure?",
                                    okLabel: "Yes");

                                if (res != OkCancelResult.ok) {
                                  return;
                                }
                                setState(() {
                                  uploadingFile = true;
                                });

                                await client.setAvatar(null);

                                setState(() {
                                  uploadingFile = false;
                                });
                              },
                            ),
                        ]),
                    SettingsSection(
                        title: const Text("Profile"),
                        tiles: <SettingsTile>[
                          SettingsTile.navigation(
                            title: const Text("Display name"),
                            trailing: const Icon(Icons.edit),
                            value: Text(p.data?.displayname ?? client.userID!),
                            onPressed: (context) => setDisplayName(p),
                          ),
                          SettingsTile(
                            title: const Text("User id"),
                            value: Text(client.userID ?? "None"),
                            trailing: const Icon(Icons.copy),
                            onPressed: (context) async {
                              await Clipboard.setData(
                                  ClipboardData(text: client.userID));
                            },
                          ),
                        ]),
                    SettingsSection(
                      title: const Text("Danger"),
                      tiles: <SettingsTile>[
                        SettingsTile.navigation(
                          title: const Text("Change password"),
                          leading: const Icon(Icons.password),
                          trailing: const Icon(Icons.edit),
                          value: Text(p.data?.displayname ?? client.userID!),
                          onPressed: (context) => changePassword(),
                        ),
                        SettingsTile.navigation(
                            leading:
                                const Icon(Icons.logout, color: Colors.red),
                            title: const Text('Logout'),
                            onPressed: (context) async {
                              final res = await showOkCancelAlertDialog(
                                  context: context,
                                  title: "Logout",
                                  message: "Are you sure?",
                                  okLabel: "Yes");

                              if (res != OkCancelResult.ok) {
                                return;
                              }

                              await client.logout();
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                              }
                            }),
                        SettingsTile.navigation(
                            leading: const Icon(Icons.delete_forever,
                                color: Colors.red),
                            title: const Text('Delete account',
                                style: TextStyle(color: Colors.red)),
                            description:
                                const Text("This operation cannot be undone."),
                            onPressed: (context) async {
                              final res = await showOkCancelAlertDialog(
                                  context: context,
                                  title: "Logout",
                                  message:
                                      "Are you sure you want to delete your account? This operation cannot be undone.",
                                  okLabel: "Yes");

                              if (res != OkCancelResult.ok) {
                                return;
                              }
                              try {
                                await client.deactivateAccount();
                              } catch (ex) {
                                await showAlertDialog(
                                    context: context,
                                    title: "Something unexpected happened",
                                    message: ex.toString());
                              }
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                              }
                            }),
                      ],
                    ),
                  ]);
            }),
      ],
    );
  }
}
