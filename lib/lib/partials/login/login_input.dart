import 'package:flutter/material.dart';

import '../../style/constants.dart';

class LoginInput extends StatelessWidget {
  const LoginInput(
      {Key? key,
      this.name,
      this.icon,
      this.tController,
      this.errorText,
      this.obscureText = false,
      this.onChanged})
      : super(key: key);
  final String? name;
  final IconData? icon;
  final TextEditingController? tController;
  final String? errorText;
  final bool obscureText;
  final void Function(String)? onChanged;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        keyboardType: TextInputType.text,
        controller: tController,
        obscureText: obscureText,
        onChanged: onChanged,
        autocorrect: false,
        decoration: Constants.kTextFieldInputDecoration.copyWith(
          errorText: errorText,
          prefixIcon: Icon(icon),
          labelText: name,
        ),
      ),
    );
  }
}
