import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:minestrix/partials/components/layouts/customHeader.dart';

import '../../utils/managers/theme_manager.dart';

class SettingsThemePage extends StatefulWidget {
  const SettingsThemePage({Key? key}) : super(key: key);

  @override
  _SettingsThemePageState createState() => _SettingsThemePageState();
}

class _SettingsThemePageState extends State<SettingsThemePage> {
  @override
  Widget build(BuildContext context) {
    AppThemeMode? themeMode = context.read<ThemeNotifier>().mode;
    return Consumer<ThemeNotifier>(
      builder: (context, theme, _) => ListView(
        children: [
          CustomHeader("Theme"),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ColorChooser(color: Colors.blue[800]!),
                ColorChooser(color: Colors.red),
                ColorChooser(color: Colors.green),
                ColorChooser(color: Colors.purple),
                ColorChooser(color: Colors.grey[900]!)
              ],
            ),
          ),
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
          Padding(
            padding: const EdgeInsets.all(30),
            child: Row(
              children: [
                Card(
                  color: Theme.of(context).primaryColor,
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("A nice story",
                            style:
                                Theme.of(context).primaryTextTheme.headline6),
                        SizedBox(height: 4),
                        Text("And it's content",
                            style:
                                Theme.of(context).primaryTextTheme.bodyText1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ColorChooser extends StatelessWidget {
  final Color color;
  const ColorChooser({Key? key, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color primaryColor = context.read<ThemeNotifier>().primaryColor;
    print(color.toString() + " " + primaryColor.toString());
    return IconButton(
        color: Colors.red,
        icon: CircleAvatar(
          child: ThemeNotifier.isColorEquals(primaryColor, color)
              ? Icon(Icons.check, color: Colors.white)
              : null,
          backgroundColor: color,
        ),
        onPressed: () {
          context.read<ThemeNotifier>().setPrimaryColor(color);
        });
  }
}
