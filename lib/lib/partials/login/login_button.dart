import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LoginButton extends StatefulWidget {
  final IconData icon;
  final AsyncCallback onPressed;
  final String text;
  final bool filled;

  const LoginButton(
      {super.key,
      required this.icon,
      required this.onPressed,
      required this.text,
      this.filled = false});

  @override
  State<LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<LoginButton> {
  bool _isLoading = false;

  void onPressed() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onPressed();
    } finally {
      _isLoading = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Widget get child => Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 14.0,
        ),
        child: _isLoading
            ? const CircularProgressIndicator()
            : Row(
                children: [
                  Icon(widget.icon),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.fontSize)),
                  ),
                ],
              ),
      );
  @override
  Widget build(BuildContext context) {
    return widget.filled
        ? FilledButton(onPressed: _isLoading ? null : onPressed, child: child)
        : FilledButton.tonal(
            onPressed: _isLoading ? null : onPressed, child: child);
  }
}
