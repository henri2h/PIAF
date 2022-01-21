import 'package:flutter/material.dart';
import 'package:minestrix/partials/components/layouts/customHeader.dart';
import 'package:minestrix/utils/Managers/ThemeManager.dart';
import 'package:provider/src/provider.dart';

class SettingsThemePage extends StatefulWidget {
  const SettingsThemePage({Key? key}) : super(key: key);

  @override
  _SettingsThemePageState createState() => _SettingsThemePageState();
}

class _SettingsThemePageState extends State<SettingsThemePage> {
  @override
  Widget build(BuildContext context) {
    AppThemeMode? themeMode = context.read<ThemeNotifier>().mode;
    return ListView(
      children: [
        CustomHeader("Theme"),
        RadioListTile(
            groupValue: themeMode,
            secondary: Icon(Icons.light_mode),
            value: AppThemeMode.light,
            onChanged: (value) {
              context.read<ThemeNotifier>().setLightMode();
              setState(() {});
            },
            title: Text("Light mode")),
        RadioListTile(
            secondary: Icon(Icons.dark_mode),
            groupValue: themeMode,
            value: AppThemeMode.dark,
            onChanged: (value) {
              context.read<ThemeNotifier>().setDarkMode();
              setState(() {});
            },
            title: Text("Dark mode")),
        RadioListTile(
            groupValue: themeMode,
            value: AppThemeMode.black,
            onChanged: (value) {
              context.read<ThemeNotifier>().setBlackMode();
              setState(() {});
            },
            title: Text("Black mode")),
      ],
    );
  }
}
