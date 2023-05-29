import 'package:flutter/material.dart';

class FakeTextField extends StatelessWidget {
  const FakeTextField(
      {Key? key,
      required this.onPressed,
      required this.icon,
      required this.text,
      this.trailing})
      : super(key: key);

  final void Function()? onPressed;
  final IconData icon;
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
        elevation: 0,
        color: _getFillColor(Theme.of(context)),
        hoverElevation: 0,
        hoverColor: _getFillColor(Theme.of(context)),
        focusElevation: 0,
        enableFeedback: false,
        focusColor: _getFillColor(Theme.of(context)),
        onPressed: onPressed,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
        child: SizedBox(
          height: 46,
          
          child: Row(
            children: [
              Icon(icon, color: Colors.grey, size: 18),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(text,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w400))),
              if (trailing != null) trailing!
            ],
          ),
        ));
  }

  Color _getFillColor(ThemeData themeData) {
    // dark theme: 10% white (enabled), 5% white (disabled)
    // light theme: 4% black (enabled), 2% black (disabled)
    const Color darkEnabled = Color.fromARGB(36, 255, 255, 255);
    const Color darkDisabled = Color.fromARGB(19, 255, 255, 255);
    const Color lightEnabled = Color(0x0A000000);
    const Color lightDisabled = Color(0x05000000);

    switch (themeData.brightness) {
      case Brightness.dark:
        return onPressed != null ? darkEnabled : darkDisabled;
      case Brightness.light:
        return onPressed != null ? lightEnabled : lightDisabled;
    }
  }
}
