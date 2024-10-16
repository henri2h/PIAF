import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/settings_key.dart';
import '../utils/famedlysdk_store.dart';

abstract class SentryController {
  static Future<void> toggleSentryAction(
      BuildContext context, bool enableSentry) async {
    if (!AppConfig.enableSentry) return;
    final storage = Store();
    await storage.setItemBool(SettingKeys.sentry, enableSentry);
    return;
  }

  static Future<bool> getSentryStatus() async {
    if (!AppConfig.enableSentry) return false;
    final storage = Store();
    try {
      return await storage.getItemBool(SettingKeys.sentry, false);
    } catch (_) {
      return false;
    }
  }
}
