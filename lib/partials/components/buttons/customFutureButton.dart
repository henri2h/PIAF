import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CustomFutureButton extends StatefulWidget {
  const CustomFutureButton(
      {Key? key,
      required this.onPressed,
      required this.text,
      required this.icon})
      : super(key: key);
  final AsyncCallback onPressed;
  final Widget icon;
  final String text;

  @override
  _CustomFutureButtonState createState() => _CustomFutureButtonState();
}

class _CustomFutureButtonState extends State<CustomFutureButton> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: loading
                    ? CircularProgressIndicator(color: Colors.white)
                    : widget.icon,
              ),
              Text(widget.text),
            ],
          ),
        ),
        onPressed: () async {
          if (loading) return;

          setState(() {
            loading = true;
          });
          try {
            await widget.onPressed();
          } finally {
            setState(() {
              loading = false;
            });
          }
        });
  }
}
