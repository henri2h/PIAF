import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:piaf/partials/components/buttons/custom_future_button.dart';

class CustomTextFutureButton extends StatelessWidget {
  const CustomTextFutureButton(
      {super.key,
      required this.onPressed,
      required this.text,
      required this.icon,
      this.color,
      this.foregroundColor,
      this.expanded = true});
  final AsyncCallback onPressed;
  final IconData icon;
  final String text;
  final bool expanded;
  final Color? color;
  final Color? foregroundColor;
  @override
  Widget build(BuildContext context) {
    return CustomFutureButton(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      icon: Icon(icon, color: foregroundColor),
      onPressed: onPressed,
      expanded: expanded,
      color: color,
      children: [
        Text(text, style: TextStyle(fontSize: 14, color: foregroundColor))
      ],
    );
  }
}
