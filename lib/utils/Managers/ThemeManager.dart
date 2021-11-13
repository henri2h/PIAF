import 'package:flutter/material.dart';
import 'package:minestrix/utils/Managers/StorageManager.dart';

class ThemeNotifier with ChangeNotifier {
  final darkTheme = ThemeData.dark();

  /*ThemeData(
    primarySwatch: MaterialColor.,
    primaryColor: Colors.black,
    brightness: Brightness.dark,
    backgroundColor: const Color(0xFF212121),
    accentColor: Colors.white,
    accentIconTheme: IconThemeData(color: Colors.black),
    dividerColor: Colors.black12,
  );*/

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
  bool _darkMode = false;
  bool isDarkMode() => _darkMode;
  ThemeData? getTheme() => _themeData;

  ThemeNotifier() {
    StorageManager.readData('themeMode').then((value) {
      print('value read from storage: ' + value.toString());
      var themeMode = value ?? 'light';
      if (themeMode == 'light') {
        _themeData = lightTheme;
        _darkMode = false;
      } else {
        print('setting dark theme');
        _themeData = darkTheme;
        _darkMode = true;
      }
      notifyListeners();
    });
  }

  void setDarkMode() async {
    _themeData = darkTheme;
    _darkMode = true;
    StorageManager.saveData('themeMode', 'dark');
    notifyListeners();
  }

  void setLightMode() async {
    _themeData = lightTheme;
    _darkMode = false;
    StorageManager.saveData('themeMode', 'light');
    notifyListeners();
  }
}
