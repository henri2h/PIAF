import 'package:flutter/material.dart';

class ConvSettingsBackButton extends StatefulWidget {
  const ConvSettingsBackButton({Key? key}) : super(key: key);

  @override
  ConvSettingsBackButtonState createState() => ConvSettingsBackButtonState();
}

class ConvSettingsBackButtonState extends State<ConvSettingsBackButton> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MaterialButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8))),
        padding: const EdgeInsets.all(14),
        minWidth: 0,
        child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.all(Radius.circular(8))),
            child: Icon(Icons.navigate_before,
                size: 18, color: Theme.of(context).colorScheme.onPrimary)),
      ),
    );
  }
}
