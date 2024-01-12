import 'package:flutter/material.dart';

class WelcomeActionsButton extends StatelessWidget {
  const WelcomeActionsButton(
      {super.key,
      required this.text,
      required this.icon,
      required this.onPressed,
      required this.subtitle,
      required this.done});

  final String text;
  final String subtitle;
  final IconData icon;
  final Future<void> Function() onPressed;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 4,
        child: ListTile(
          leading: Icon(icon),
          title: Text(text),
          subtitle: Text(subtitle),
          onTap: done ? null : onPressed,
          trailing: done
              ? CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(
                    Icons.done,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ))
              : null,
        ),
      ),
    );
  }
}
