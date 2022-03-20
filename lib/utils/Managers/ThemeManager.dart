import 'package:flutter/material.dart';
import 'package:minestrix_chat/helpers/storage_manager.dart';

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
      bottomNavigationBarTheme:
          BottomNavigationBarThemeData(backgroundColor: Colors.black),
      cardColor: Colors.grey[900],
      brightness: Brightness.dark,
    );

    _darkTheme = ThemeData.dark().copyWith(primaryColor: _primaryColor);
    _lightTheme = ThemeData.light().copyWith(primaryColor: _primaryColor);
  }

  /*ThemeData(
    primarySwatch: Colors.black,
    primaryColor: Colors.white,
    brightness: Brightness.light,
    backgroundColor: const Color(0xFFE5E5E5),
    accentColor: Colors.black,
    accentIconTheme: IconThemeData(color: Colors.white),
    dividerColor: Colors.white54,
  );*/

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
    } catch (e) {}

    _buildTheme();

    var value = await StorageManager.readData('themeMode');

    print('theme: ' + value.toString());

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
        _themeData = _lightTheme;
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
