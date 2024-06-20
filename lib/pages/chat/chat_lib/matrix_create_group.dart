library minestrix_chat;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:matrix/matrix.dart';

import '../../../partials/style/constants.dart';

@RoutePage()
class MatrixCreateGroup extends StatefulWidget {
  final Client client;
  final void Function(String)? onGroupCreated;

  const MatrixCreateGroup(
      {super.key, required this.client, this.onGroupCreated});

  @override
  MatrixCreateGroupState createState() => MatrixCreateGroupState();
}

class MatrixCreateGroupState extends State<MatrixCreateGroup> {
  String? errorText;

  TextEditingController tName = TextEditingController();
  TextEditingController tDesc = TextEditingController();

  bool _isE2EEnabled = true;
  bool _isPublicGroup = false;
  bool _creating = false;

  void _createGroup() async {
    if (tName.text != "") {
      setState(() {
        _creating = true;
      });

      final roomId = await widget.client.createGroupChat(
          groupName: tName.text,
          enableEncryption: _isE2EEnabled,
          preset: _isPublicGroup
              ? CreateRoomPreset.publicChat
              : CreateRoomPreset.privateChat,
          visibility: _isPublicGroup ? Visibility.public : Visibility.private);

      if (tDesc.text.isNotEmpty) {
        Room? r = widget.client.getRoomById(roomId);
        await r?.setDescription(tDesc.text);
      }

      if (mounted) {
        setState(() {
          _creating = false;
          errorText = "success";
        });
        Navigator.of(context).pop();
      }

      widget.onGroupCreated?.call(roomId);
    } else {
      setState(() {
        errorText = "Name can't be null";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: ListView(
            children: [
              TextField(
                controller: tName,
                decoration: Constants.kTextFieldInputDecoration.copyWith(
                    labelText: "Group name",
                    prefixIcon: const Icon(Icons.edit)),
              ),
              const SizedBox(height: 15),
              TextField(
                  controller: tDesc,
                  decoration: Constants.kTextFieldInputDecoration.copyWith(
                      labelText: "Topic (optional)",
                      prefixIcon: const Icon(Icons.text_fields)),
                  minLines: 3,
                  maxLines: null),
              const SizedBox(height: 30),
              Column(
                children: [
                  SwitchListTile(
                      title: const Text("Make this group public",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      secondary: const Icon(Icons.public),
                      subtitle: const Text(
                          'Private group can only be joined with invitation'),
                      value: _isPublicGroup,
                      onChanged: (value) {
                        _isPublicGroup = value;
                        setState(() {});
                      }),
                  SwitchListTile(
                      title: const Text("Enable end-to-end encryption",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      secondary: const Icon(Icons.lock),
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
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          MaterialButton(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            color: Theme.of(context).colorScheme.primary,
            disabledColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
            onPressed: _creating ? null : _createGroup,
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
    ]);
  }
}
