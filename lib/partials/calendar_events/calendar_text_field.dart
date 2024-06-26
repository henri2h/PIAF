import 'package:flutter/material.dart';
import 'package:piaf/partials/style/constants.dart';

import 'calendar_section.dart';

class CreateCalendarTextField extends StatelessWidget {
  const CreateCalendarTextField(
      {super.key,
      required this.text,
      this.controller,
      required this.icon,
      this.maxLines = 1,
      this.minLines});
  final TextEditingController? controller;
  final String text;
  final Icon icon;
  final int? minLines;
  final int? maxLines;
  @override
  Widget build(BuildContext context) {
    return CreateCalendarSection(
      text: text,
      child: TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          decoration: Constants.kTextFieldInputDecoration
              .copyWith(prefixIcon: icon, hintText: text)),
    );
  }
}
