import 'dart:convert';

import 'package:minestrix_chat/helpers/storage_manager.dart';

class Settings {
  final _calendar = "calendar";
  final _multipleFeed = "multiple_feed";
  final _optimizedFeed = "optimized_feed";
  final _shareEnabled = "share_enabled";

  bool get multipleFeedSupport => _settings[_multipleFeed] ?? false;
  bool get optimizedFeed => _settings[_optimizedFeed] ?? false;
  bool get shareEnabled => _settings[_shareEnabled] ?? false;


  set multipleFeedSupport(bool value) {
    _settings[_multipleFeed] = value;
    saveData();
  }

  set optimizedFeed(bool value) {
    _settings[_optimizedFeed] = value;
    saveData();
  }

  set shareEnabled(bool value) {
    _settings[_shareEnabled] = value;
    saveData();
  }

  static Map<String, dynamic> _settings = {};

  Future<void> loadAllValues() async {
    _settings = jsonDecode(await StorageManager.readData("settings") ?? "{}");
  }

  Future<void> saveData() async {
    StorageManager.saveData("settings", jsonEncode(_settings));
  }

  static bool _loaded = false;

  Future<void> loadGuarded() async {
    if (!_loaded) {
      await loadAllValues();
      _loaded = true;
    }
  }

  Settings();
}
