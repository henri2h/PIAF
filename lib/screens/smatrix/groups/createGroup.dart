import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';

class CreateGroup extends StatefulWidget {
  @override
  _CreateGroupState createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  String errorText = null;
  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;

    TextEditingController tName = TextEditingController();
    TextEditingController tDesc = TextEditingController();

    return Container(
        child: ListView(
      children: [
        H1Title("Create group"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            children: [
              TextField(
                controller: tName,
                decoration: InputDecoration(
                  labelText: "Group name",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  filled: true,
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: tDesc,
                decoration: InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  errorText: errorText,
                  filled: true,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(40.0),
          child: MinesTrixButton(
              label: "Create group",
              onPressed: () async {
                if (tName.text != "") {
                  await sclient.createSMatrixRoom("#" + tName.text, tDesc.text);
                  setState(() {
                    errorText = "success";
                  });
                } else
                  setState(() {
                    errorText = "Name can't be null";
                  });
              },
              icon: Icons.group_add),
        )
      ],
    ));
  }
}
