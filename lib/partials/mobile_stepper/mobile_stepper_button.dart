import 'package:flutter/material.dart';

class MobileStepperButton extends StatelessWidget {
  const MobileStepperButton(
      {super.key,
      required this.onPressed,
      required this.children,
      required this.enabled});

  final void Function()? onPressed;
  final bool enabled;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: enabled
          ? MaterialButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              color: Colors.green,
              onPressed: onPressed,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: children),
              ))
          : null,
    );
  }
}
