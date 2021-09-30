import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:localstorage/localstorage.dart';
import 'package:minestrix/utils/platforms_info.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:core';

class Store {
  LocalStorage storage;
  final FlutterSecureStorage secureStorage;

  Store()
      : secureStorage = PlatformInfos.isMobile ? FlutterSecureStorage() : null;

  Future<void> _setupLocalStorage() async {
    if (storage == null) {
      final directory = PlatformInfos.isBetaDesktop
          ? await getApplicationSupportDirectory()
          : (PlatformInfos.isWeb
              ? null
              : await getApplicationDocumentsDirectory());
      storage = LocalStorage('LocalStorage', directory?.path);
      await storage.ready;
    }
  }

  Future<String> getItem(String key) async {
    if (!PlatformInfos.isMobile) {
      await _setupLocalStorage();
      try {
        return storage.getItem(key)?.toString();
      } catch (_) {
        return null;
      }
    }
    try {
      return await secureStorage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<bool> getItemBool(String key, [bool defaultValue]) async {
    final value = await getItem(key);
    if (value == null) {
      return defaultValue ?? false;
    }
    // we also check for '1' for legacy reasons, some booleans were stored that way
    return value == '1' || value.toLowerCase() == 'true';
  }

  Future<void> setItem(String key, String value) async {
    if (!PlatformInfos.isMobile) {
      await _setupLocalStorage();
      return await storage.setItem(key, value);
    }
    return await secureStorage.write(key: key, value: value);
  }

  Future<void> deleteItem(String key) async {
    if (!PlatformInfos.isMobile) {
      await _setupLocalStorage();
      return await storage.deleteItem(key);
    }
    return await secureStorage.delete(key: key);
  }
}
