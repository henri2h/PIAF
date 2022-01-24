import 'package:flutter/material.dart';
import 'package:minestrix/partials/components/layouts/customHeader.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';

class CreateGroupPage extends StatefulWidget {
  @override
  _CreateGroupPageState createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  String? errorText = null;
  @override
  Widget build(BuildContext context) {
    MinestrixClient? sclient = Matrix.of(context).sclient;

    TextEditingController tName = TextEditingController();
    TextEditingController tDesc = TextEditingController();

    bool _isE2EEnabled = true;
    bool _isPublicGroup = false;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                CustomHeader("Create group"),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: tName,
                        decoration: InputDecoration(
                          labelText: "Group name",
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15))),
                          filled: true,
                        ),
                      ),
                      SizedBox(height: 15),
                      TextField(
                        controller: tDesc,
                        decoration: InputDecoration(
                          labelText: "Topic (optional)",
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15))),
                          errorText: errorText,
                          filled: true,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Make this group public",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  "Private group can only be joined with invitation")
                            ],
                          ),
                          Switch(
                              value: _isPublicGroup,
                              onChanged: (value) {
                                _isPublicGroup = value;
                                setState(() {});
                              }),
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              Text("You can't disable it later.")
                            ],
                          ),
                          Switch(
                              value: _isE2EEnabled,
                              onChanged: (value) {
                                _isE2EEnabled = value;
                                setState(() {});
                              }),
                        ],
                      ),
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
              OutlinedButton(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text('Abort'),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              SizedBox(width: 10),
              ElevatedButton(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text('Create group'),
                ),
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
            ]),
          )
        ],
      ),
    );
  }
}
