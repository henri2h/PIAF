import 'package:flutter/material.dart';

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
  final Function? onChanged;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        keyboardType: TextInputType.text,
        controller: tController,
        obscureText: obscureText,
        onChanged: onChanged as void Function(String)?,
        autocorrect: false,
        decoration: InputDecoration(
          errorText: errorText,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8))),
          filled: true,
          icon: Icon(icon),
          labelText: name,
        ),
      ),
    );
  }
}
