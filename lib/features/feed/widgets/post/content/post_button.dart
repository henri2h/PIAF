import 'package:flutter/material.dart';

class PostButton extends StatelessWidget {
  const PostButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onPressed,
    this.iconOnly = false,
  });

  final IconData icon;
  final String text;
  final bool iconOnly;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      elevation: 0,
      minWidth: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          if (!iconOnly) const SizedBox(width: 5),
          if (!iconOnly) Text(text)
        ],
      ),
    );
  }
}
