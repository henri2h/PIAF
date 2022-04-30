import 'package:flutter/material.dart' hide Visibility;

import 'package:matrix/matrix.dart';

import 'package:minestrix/partials/components/layouts/customHeader.dart';
import 'package:minestrix/utils/matrix_widget.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';

class CreateGroupPage extends StatefulWidget {
  @override
  _CreateGroupPageState createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  bool _isE2EEnabled = true;
  bool _isPublicGroup = false;
  bool _creating = false;

  TextEditingController tName = TextEditingController();
  TextEditingController tDesc = TextEditingController();

  String? errorText = null;
  @override
  Widget build(BuildContext context) {
    Client? sclient = Matrix.of(context).client;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                CustomHeader(title: "Create MinesTRIX group"),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: tName,
                        decoration: InputDecoration(
                          labelText: "Group name",
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
                          errorText: errorText,
                          filled: true,
                        ),
                      ),
                      SizedBox(height: 15),
                      TextField(
                        controller: tDesc,
                        decoration: InputDecoration(
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
                          title: Text("Make this group public",
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              "Private group can only be joined with invitation"),
                          value: _isPublicGroup,
                          onChanged: (value) {
                            _isPublicGroup = value;
                            setState(() {});
                          }),
                      SwitchListTile(
                          title: Text("Enable end-to-end encryption",
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold)),
                          subtitle: Text("You can't disable it later"),
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
                SizedBox(height: 30),
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
                          style:
                              TextStyle(color: Theme.of(context).primaryColor)),
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              SizedBox(width: 10),
              MaterialButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                color: Theme.of(context).primaryColor,
                disabledColor: Theme.of(context).primaryColor.withOpacity(0.8),
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
                onPressed: _creating
                    ? null
                    : () async {
                        if (tName.text != "") {
                          setState(() {
                            _creating = true;
                          });
                          String roomId = await sclient.createMinestrixGroup(
                              "#" + tName.text, tDesc.text,
                              visibility: _isPublicGroup
                                  ? Visibility.public
                                  : Visibility.private);
                          if (!_isPublicGroup && _isE2EEnabled) {
                            Room? r = sclient.getRoomById(roomId);
                            if (r != null) {
                              await r.enableEncryption();
                            }
                          }

                          Navigator.of(context).pop();

                          if (mounted)
                            setState(() {
                              _creating = false;
                              errorText = "success";
                            });
                        } else
                          setState(() {
                            errorText = "Name can't be null";
                          });
                      },
              )
            ]),
          )
        ],
      ),
    );
  }
}
