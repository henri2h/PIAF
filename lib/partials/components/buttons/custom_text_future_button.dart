import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:minestrix/partials/components/buttons/custom_future_button.dart';

class CustomTextFutureButton extends StatelessWidget {
  const CustomTextFutureButton(
      {Key? key,
      required this.onPressed,
      required this.text,
      required this.icon,
      this.color,
      this.expanded = true})
      : super(key: key);
  final AsyncCallback onPressed;
  final IconData icon;
  final String text;
  final bool expanded;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return CustomFutureButton(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      icon: Icon(icon),
      onPressed: onPressed,
      expanded: expanded,
      color: color,
      children: [Text(text, style: const TextStyle(fontSize: 14))],
    );
  }
}
