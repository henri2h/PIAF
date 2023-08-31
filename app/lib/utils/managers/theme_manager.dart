import 'package:flutter/material.dart';

import 'package:minestrix_chat/helpers/storage_manager.dart';

import '../platforms_info.dart';

enum AppThemeMode { dark, light, auto }

class ThemeNotifier with ChangeNotifier {
  TextTheme? get textTheme => PlatformInfos.isDesktop
      ? Typography.material2018().black.merge(ThemeNotifier.fallbackTextTheme)
      : null;

  static const fallbackTextStyle =
      TextStyle(fontFamily: 'Roboto', fontFamilyFallback: ['NotoEmoji']);

  static var fallbackTextTheme = const TextTheme(
    bodyLarge: fallbackTextStyle,
    bodyMedium: fallbackTextStyle,
    labelLarge: fallbackTextStyle,
    bodySmall: fallbackTextStyle,
    labelSmall: fallbackTextStyle,
    displayLarge: fallbackTextStyle,
    displayMedium: fallbackTextStyle,
    displaySmall: fallbackTextStyle,
    headlineMedium: fallbackTextStyle,
    headlineSmall: fallbackTextStyle,
    titleLarge: fallbackTextStyle,
    titleMedium: fallbackTextStyle,
    titleSmall: fallbackTextStyle,
  );

  AppThemeMode? appMode;
  ThemeMode? get mode {
    switch (appMode) {
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.light:
        return ThemeMode.light;

      case AppThemeMode.auto:
        return null;
      case null:
        return null;
    }
  }

  ThemeNotifier() {
    _loadDataFromStorage();
  }

  Future<void> _loadDataFromStorage() async {
    var value = await StorageManager.readData('themeMode');

    appMode = AppThemeMode.values.firstWhere(
        (e) => e.toString() == value.toString(),
        orElse: () => AppThemeMode.auto);

    notifyListeners();
  }

  void _setMode(AppThemeMode t) {
    StorageManager.saveData('themeMode', t.toString());
    appMode = t;
    notifyListeners();
  }

  void setAutoMode() async {
    _setMode(AppThemeMode.auto);
  }

  void setDarkMode() async {
    _setMode(AppThemeMode.dark);
  }

  void setLightMode() async {
    _setMode(AppThemeMode.light);
  }
}
