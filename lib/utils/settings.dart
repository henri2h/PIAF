import 'dart:convert';

import 'package:minestrix_chat/helpers/storage_manager.dart';

class Settings {
  bool get calendarEventSupport => _settings["calendar"] ?? false;
  set calendarEventSupport(bool value) {
    _settings["calendar"] = value;
    saveData();
  }

  Map<String, dynamic> _settings = {};

  Future<void> loadAllValues() async {
    _settings = jsonDecode(await StorageManager.readData("settings") ?? "{}");
  }

  Future<void> saveData() async {
    StorageManager.saveData("settings", jsonEncode(_settings));
  }

  Settings() {
    loadAllValues();
  }
}
