import 'package:flutter/material.dart';

class LoginInput extends StatelessWidget {
  const LoginInput(
      {super.key,
      this.name,
      this.icon,
      this.tController,
      this.errorText,
      this.obscureText = false,
      this.onChanged,
      this.hintText});

  final String? name;
  final IconData? icon;
  final TextEditingController? tController;
  final String? errorText;
  final bool obscureText;
  final void Function(String)? onChanged;
  final String? hintText;

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
        decoration: InputDecoration(
            errorText: errorText,
            prefixIcon: Icon(icon),
            labelText: name,
            hintText: hintText,
            border: const OutlineInputBorder()),
      ),
    );
  }
}
