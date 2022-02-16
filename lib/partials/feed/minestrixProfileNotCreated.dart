import 'package:flutter/material.dart';
import 'package:minestrix/partials/components/buttons/customFutureButton.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';

class MinestrixProfileNotCreated extends StatelessWidget {
  const MinestrixProfileNotCreated({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MinestrixClient? sclient = Matrix.of(context).sclient;

    return CustomFutureButton(
        icon: Icon(Icons.skateboarding_outlined,
            color: Theme.of(context).colorScheme.onPrimary),
        color: Theme.of(context).primaryColor,
        children: [
          Text("Create your account",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onPrimary)),
          Text("No profile was found",
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onPrimary)),
        ],
        onPressed: sclient?.createSMatrixUserProfile);
  }
}
