import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide Visibility;

import 'package:matrix/matrix.dart';

import 'package:minestrix/partials/components/layouts/custom_header.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';

@RoutePage()
class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({Key? key}) : super(key: key);

  @override
  CreateGroupPageState createState() => CreateGroupPageState();
}

class CreateGroupPageState extends State<CreateGroupPage> {
  bool _isE2EEnabled = true;
  bool _isPublicGroup = false;
  bool _creating = false;

  TextEditingController tName = TextEditingController();
  TextEditingController tDesc = TextEditingController();

  String? errorText;
  @override
  Widget build(BuildContext context) {
    Client? sclient = Matrix.of(context).client;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                const CustomHeader(title: "Create MinesTRIX group"),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: tName,
                        decoration: InputDecoration(
                          labelText: "Group name",
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.all(
                              Radius.circular(15),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.all(
                              Radius.circular(15),
                            ),
                          ),
                          errorText: errorText,
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: tDesc,
                        decoration: const InputDecoration(
                          labelText: "Topic (optional)",
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.all(
                              Radius.circular(15),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.all(
                              Radius.circular(15),
                            ),
                          ),
                          filled: true,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      SwitchListTile(
                          title: const Text("Make this group public",
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold)),
                          subtitle: const Text(
                              "Private group can only be joined with invitation"),
                          value: _isPublicGroup,
                          onChanged: (value) {
                            _isPublicGroup = value;
                            setState(() {});
                          }),
                      SwitchListTile(
                          title: const Text("Enable end-to-end encryption",
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold)),
                          subtitle: const Text("You can't disable it later"),
                          value: _isE2EEnabled,
                          onChanged: _isPublicGroup == true
                              ? null
                              : (value) {
                                  _isE2EEnabled = value;
                                  setState(() {});
                                }),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              MaterialButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                color: Theme.of(context).colorScheme.onPrimary,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 60,
                    child: Center(
                      child: Text('Abort',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary)),
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(width: 10),
              MaterialButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                color: Theme.of(context).colorScheme.primary,
                disabledColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                onPressed: _creating
                    ? null
                    : () async {
                        if (tName.text != "") {
                          setState(() {
                            _creating = true;
                          });
                          String roomId = await sclient.createMinestrixGroup(
                              "#${tName.text}", tDesc.text,
                              visibility: _isPublicGroup
                                  ? Visibility.public
                                  : Visibility.private);
                          if (!_isPublicGroup && _isE2EEnabled) {
                            Room? r = sclient.getRoomById(roomId);
                            if (r != null) {
                              await r.enableEncryption();
                            }
                          }
                          if (mounted) {
                            Navigator.of(context).pop();
                          }

                          if (mounted) {
                            setState(() {
                              _creating = false;
                              errorText = "success";
                            });
                          }
                        } else {
                          setState(() {
                            errorText = "Name can't be null";
                          });
                        }
                      },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      if (_creating)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.onPrimary),
                          ),
                        ),
                      Text('Create group',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary)),
                    ],
                  ),
                ),
              )
            ]),
          )
        ],
      ),
    );
  }
}
