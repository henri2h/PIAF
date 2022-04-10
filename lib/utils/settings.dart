import 'dart:convert';

import 'package:minestrix_chat/helpers/storage_manager.dart';

class Settings {
  final _calendar = "calendar";
  final _multipleFeed = "multiple_feed";

  bool get multipleFeedSupport => _settings[_multipleFeed] ?? false;
  bool get calendarEventSupport => _settings[_calendar] ?? false;

  set calendarEventSupport(bool value) {
    _settings[_calendar] = value;
    saveData();
  }

  set multipleFeedSupport(bool value) {
    _settings[_multipleFeed] = value;
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
