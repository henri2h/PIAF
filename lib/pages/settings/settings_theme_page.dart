import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/managers/theme_manager.dart';

@RoutePage()
class SettingsThemePage extends StatefulWidget {
  const SettingsThemePage({super.key});

  @override
  SettingsThemePageState createState() => SettingsThemePageState();
}

class SettingsThemePageState extends State<SettingsThemePage> {
  @override
  Widget build(BuildContext context) {
    AppThemeMode? themeMode = context.read<ThemeNotifier>().appMode;
    return Scaffold(
      appBar: AppBar(title: const Text("Theme")),
      body: Consumer<ThemeNotifier>(
        builder: (context, theme, _) => ListView(
          children: [
            RadioListTile(
                groupValue: themeMode,
                secondary: const Icon(Icons.light_mode),
                value: AppThemeMode.light,
                onChanged: (value) {
                  context.read<ThemeNotifier>().setLightMode();
                  setState(() {});
                },
                title: const Text("Light mode")),
            RadioListTile(
                groupValue: themeMode,
                secondary: const Icon(Icons.dark_mode),
                value: AppThemeMode.dark,
                onChanged: (value) {
                  context.read<ThemeNotifier>().setDarkMode();
                  setState(() {});
                },
                title: const Text("Dark mode")),
            RadioListTile(
                groupValue: themeMode,
                value: AppThemeMode.auto,
                onChanged: (value) {
                  context.read<ThemeNotifier>().setAutoMode();
                  setState(() {});
                },
                title: const Text("System mode")),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Row(
                children: [
                  Card(
                    color: Theme.of(context).colorScheme.primary,
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("A nice story",
                              style: Theme.of(context)
                                  .primaryTextTheme
                                  .bodyLarge
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary)),
                          const SizedBox(height: 4),
                          Text("And it's content",
                              style: Theme.of(context)
                                  .primaryTextTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
