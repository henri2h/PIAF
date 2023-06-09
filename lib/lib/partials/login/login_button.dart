import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LoginButton extends StatefulWidget {
  final IconData icon;
  final AsyncCallback onPressed;
  final String text;
  const LoginButton(
      {Key? key,
      required this.icon,
      required this.onPressed,
      required this.text})
      : super(key: key);

  @override
  State<LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<LoginButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: MaterialButton(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8))),
            color: Theme.of(context).colorScheme.primary,
            onPressed: _isLoading
                ? null
                : () async {
                    if (_isLoading) return;

                    setState(() {
                      _isLoading = true;
                    });
                    try {
                      await widget.onPressed();
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(widget.icon,
                      color: Theme.of(context).colorScheme.onPrimary),
                  const SizedBox(width: 8),
                  Text(widget.text,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary)),
                ],
              ),
            )));
  }
}
