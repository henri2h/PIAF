import 'package:flutter/material.dart';

class H1Title extends StatelessWidget {
  const H1Title(this.title, {super.key});
  final String? title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(title!,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
    );
  }
}

class H2Title extends StatelessWidget {
  const H2Title(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(title,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
    );
  }
}

class H3Title extends StatelessWidget {
  const H3Title(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 19)),
    );
  }
}
