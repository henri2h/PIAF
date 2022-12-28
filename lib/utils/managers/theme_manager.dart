import 'package:flutter/material.dart';

import 'package:minestrix_chat/helpers/storage_manager.dart';

import '../platforms_info.dart';

enum AppThemeMode { dark, light, black }

class ThemeNotifier with ChangeNotifier {
  Color get primaryColor => _primaryColor;
  Color _primaryColor = Colors.blue[800]!;

  ThemeData? _blackTheme;
  ThemeData? _darkTheme;
  ThemeData? _lightTheme;

  void _buildTheme() {
    _blackTheme = ThemeData(
        primaryColor: _primaryColor,
        scaffoldBackgroundColor: Colors.black,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        bottomNavigationBarTheme:
            const BottomNavigationBarThemeData(backgroundColor: Colors.black),
        cardColor: Colors.grey[900],
        brightness: Brightness.dark,
        textTheme: PlatformInfos.isDesktop
            ? Typography.material2018().white.merge(fallbackTextTheme)
            : null);

    _darkTheme = ThemeData.dark().copyWith(
        primaryColor: _primaryColor,
        textTheme: PlatformInfos.isDesktop
            ? Typography.material2018().white.merge(fallbackTextTheme)
            : null);
    _lightTheme = ThemeData.light().copyWith(
        primaryColor: _primaryColor,
        textTheme: PlatformInfos.isDesktop
            ? Typography.material2018().black.merge(fallbackTextTheme)
            : null);
  }

  static const fallbackTextStyle =
      TextStyle(fontFamily: 'Roboto', fontFamilyFallback: ['NotoEmoji']);

  static var fallbackTextTheme = const TextTheme(
    bodyText1: fallbackTextStyle,
    bodyText2: fallbackTextStyle,
    button: fallbackTextStyle,
    caption: fallbackTextStyle,
    overline: fallbackTextStyle,
    headline1: fallbackTextStyle,
    headline2: fallbackTextStyle,
    headline3: fallbackTextStyle,
    headline4: fallbackTextStyle,
    headline5: fallbackTextStyle,
    headline6: fallbackTextStyle,
    subtitle1: fallbackTextStyle,
    subtitle2: fallbackTextStyle,
  );

  ThemeData? _themeData;
  ThemeData? get theme => _themeData;

  AppThemeMode? _mode;
  AppThemeMode? get mode => _mode;

  ThemeNotifier() {
    _loadDataFromStorage();
  }

  Future<void> _loadDataFromStorage() async {
    var color = await StorageManager.readData('color');

    try {
      String valueString =
          color.split('(0x')[1].split(')')[0]; // kind of hacky..
      int value = int.parse(valueString, radix: 16);
      _primaryColor = Color(value);
    } catch (_) {}

    _buildTheme();

    var value = await StorageManager.readData('themeMode');

    _mode = AppThemeMode.values.firstWhere(
        (e) => e.toString() == value.toString(),
        orElse: () => AppThemeMode.light);

    _loadMode();
  }

  void _setMode(AppThemeMode t) {
    StorageManager.saveData('themeMode', t.toString());
    _mode = t;
    _loadMode();
  }

  void _loadMode() {
    switch (_mode) {
      case AppThemeMode.light:
        _themeData = _lightTheme;
        break;

      case AppThemeMode.dark:
        _themeData = _darkTheme;
        break;
      case AppThemeMode.black:
        _themeData = _blackTheme;
        break;
      default:
        _themeData = _blackTheme;
    }

    notifyListeners();
  }

  void setBlackMode() async {
    _setMode(AppThemeMode.black);
  }

  void setDarkMode() async {
    _setMode(AppThemeMode.dark);
  }

  void setLightMode() async {
    _setMode(AppThemeMode.light);
  }

  void setPrimaryColor(Color color) {
    StorageManager.saveData('color', color.toString());
    _primaryColor = color;
    _buildTheme();
    _loadMode();
    notifyListeners();
  }

  static isColorEquals(Color a, Color b) {
    return a.toString().split('(0x')[1].split(')')[0] ==
        b.toString().split('(0x')[1].split(')')[0];
  }
}
