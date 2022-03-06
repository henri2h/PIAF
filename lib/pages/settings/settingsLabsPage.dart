import 'package:flutter/material.dart';
import 'package:minestrix/partials/components/layouts/customHeader.dart';

class SettingsLabsPage extends StatefulWidget {
  const SettingsLabsPage({Key? key}) : super(key: key);

  @override
  State<SettingsLabsPage> createState() => _SettingsLabsPageState();
}

class _SettingsLabsPageState extends State<SettingsLabsPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        children: [CustomHeader("Labs")],
      ),
    );
  }
}
