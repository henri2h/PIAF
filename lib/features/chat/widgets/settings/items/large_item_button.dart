import 'package:flutter/material.dart';

class LargeIconButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final void Function() onPressed;
  const LargeIconButton(
      {super.key,
      required this.icon,
      required this.title,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: FilledButton.tonal(
            onPressed: onPressed,
            style: const ButtonStyle(
                padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
                    EdgeInsets.all(8)),
                shape: WidgetStatePropertyAll<OutlinedBorder?>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16))))),
            child: SizedBox(width: 48, height: 48, child: Icon(icon, size: 28)),
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge,
        )
      ],
    );
  }
}
