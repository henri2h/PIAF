import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/layouts/customHeader.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';

class SettingsProfilePage extends StatefulWidget {
  const SettingsProfilePage({Key? key}) : super(key: key);

  @override
  _SettingsProfilePageState createState() => _SettingsProfilePageState();
}

class _SettingsProfilePageState extends State<SettingsProfilePage> {
  TextEditingController? displayNameController;
  bool savingDisplayName = false;

  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;

    return ListView(
      children: [
        CustomHeader("Profile"),
        FutureBuilder(
            future: sclient.getUserProfile(sclient.userID!),
            builder: (context, AsyncSnapshot<ProfileInformation> p) {
              if (displayNameController == null && p.hasData == true) {
                displayNameController = new TextEditingController(
                    text: (p.data!.displayname ?? sclient.userID!));
              }

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (displayNameController != null)
                          SizedBox(
                            width: 200,
                            child: TextField(
                              controller: displayNameController,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'User name',
                                  hintText: 'User name'),
                              onChanged: (_) {
                                setState(() {});
                              },
                            ),
                          ),
                        SizedBox(width: 10),
                        if (displayNameController?.text != p.data?.displayname)
                          ElevatedButton(
                            child: SizedBox(
                              height: 50,
                              child: Row(
                                children: [
                                  if (savingDisplayName)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: CircularProgressIndicator(
                                          color: Colors.white),
                                    ),
                                  Text("Save"),
                                ],
                              ),
                            ),
                            onPressed: () async {
                              if (displayNameController?.text !=
                                  null) if (savingDisplayName != true) {
                                setState(() {
                                  savingDisplayName = true;
                                });
                                await sclient.setDisplayName(sclient.userID!,
                                    displayNameController?.text);
                                setState(() {
                                  savingDisplayName = false;
                                });
                              }
                            },
                          ),
                        SizedBox(width: 10),
                        MatrixUserImage(
                          client: Matrix.of(context).sclient,
                          url: p.data?.avatarUrl,
                          width: 48,
                          height: 48,
                          thumnail: true,
                          rounded: true,
                          defaultIcon: Icon(Icons.person, size: 32),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(sclient.userID!),
                    ),
                  ],
                ),
              );
            }),
        MaterialButton(
            color: Colors.red,
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(Icons.exit_to_app, color: Colors.white),
                  SizedBox(width: 10),
                  Text("logout", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            onPressed: () async {
              await sclient.logout();
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            }),
      ],
    );
  }
}
