import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';

class CreateGroup extends StatefulWidget {
  @override
  _CreateGroupState createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  String? errorText = null;
  @override
  Widget build(BuildContext context) {
    MinestrixClient? sclient = Matrix.of(context).sclient;

    TextEditingController tName = TextEditingController();
    TextEditingController tDesc = TextEditingController();

    return SimpleDialog(title: H1Title("Create a new group"), children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            TextField(
              controller: tName,
              decoration: InputDecoration(
                labelText: "Group name",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15))),
                filled: true,
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: tDesc,
              decoration: InputDecoration(
                labelText: "Topic (optional)",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15))),
                errorText: errorText,
                filled: true,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Make this group public",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    Text("Private group can only be joined with invitation")
                  ],
                ),
                Switch(value: true, onChanged: (value) {}),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Enable end-to-end encryption",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    Text("You can't disable it later.")
                  ],
                ),
                Switch(value: true, onChanged: (value) {}),
              ],
            ),
            SizedBox(height: 30),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton(
                child: Text('Abort'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              SizedBox(width: 10),
              ElevatedButton(
                child: Text('Create group'),
                onPressed: () async {
                  if (tName.text != "") {
                    await sclient!
                        .createMinestrixGroup("#" + tName.text, tDesc.text);
                    setState(() {
                      errorText = "success";
                    });
                  } else
                    setState(() {
                      errorText = "Name can't be null";
                    });
                },
              )
            ])
          ],
        ),
      ),
    ]);
  }
}
