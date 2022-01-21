import 'package:flutter/material.dart';
import 'package:minestrix/utils/Managers/StorageManager.dart';

enum AppThemeMode { dark, light, black }

class ThemeNotifier with ChangeNotifier {
  final blackTheme = ThemeData(
    primaryColor: Colors.blue[800],
    scaffoldBackgroundColor: Colors.black,
    cardColor: Colors.grey[900],
    brightness: Brightness.dark,
  );

  final darkTheme = ThemeData.dark();
  final lightTheme = ThemeData.light();

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
    StorageManager.readData('themeMode').then((value) {
      print('value read from storage: ' + value.toString());
      _mode = AppThemeMode.values.firstWhere(
          (e) => e.toString() == value.toString(),
          orElse: () => AppThemeMode.light);

      _loadMode();
    });
  }

  void _setMode(AppThemeMode t) {
    StorageManager.saveData('themeMode', t.toString());
    _mode = t;
    _loadMode();
  }

  void _loadMode() {
    switch (_mode) {
      case AppThemeMode.light:
        _themeData = lightTheme;
        break;

      case AppThemeMode.dark:
        _themeData = darkTheme;
        break;
      case AppThemeMode.black:
        _themeData = blackTheme;
        break;
      default:
        _themeData = lightTheme;
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
}
