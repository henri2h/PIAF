import 'package:flutter/material.dart';
import 'package:minestrix/partials/components/buttons/customFutureButton.dart';

class MinestrixProfileNotCreated extends StatelessWidget {
  const MinestrixProfileNotCreated({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomFutureButton(
        icon: Icon(Icons.skateboarding_outlined),
        color: Theme.of(context).primaryColor,
        children: [
          Text("Create your account",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text("No profile was found", style: TextStyle(fontSize: 14)),
        ],
        onPressed: () async {});
  }
}
