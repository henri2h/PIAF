import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';

class CreateGroup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: ListView(
          children: [
            H1Title("Create group"),
            
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: MinesTrixButton(
                  label: "Create group", onPressed: () {}, icon: Icons.group_add),
            )
          ],
        ));
  }
}
