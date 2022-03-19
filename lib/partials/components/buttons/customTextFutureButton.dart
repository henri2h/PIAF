import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/partials/components/buttons/customFutureButton.dart';

class CustomTextFutureButton extends StatelessWidget {
  const CustomTextFutureButton(
      {Key? key,
      required this.onPressed,
      required this.text,
      required this.icon,
      this.expanded = true})
      : super(key: key);
  final AsyncCallback onPressed;
  final Widget icon;
  final String text;
  final bool expanded;
  @override
  Widget build(BuildContext context) {
    return CustomFutureButton(
        icon: icon,
        onPressed: onPressed,
        children: [Text(text)],
        expanded: expanded);
  }
}
