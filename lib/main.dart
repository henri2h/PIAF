import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:minestrix/app.dart';
import 'package:minestrix/utils/Managers/ThemeManager.dart';
import 'package:provider/provider.dart';

/// Load database
Future<bool> loadHive() async {
  // if (PlatformInfos.isBetaDesktop) {
  //   Hive.init((await getApplicationSupportDirectory()).path);
  // } else {
  //   await Hive.initFlutter();
  // }
  return true;
}

void main() {
  Logger.root.level = Level.ALL;
  runApp(ChangeNotifierProvider<ThemeNotifier>(
      create: (_) => new ThemeNotifier(), child: Minestrix()));
}
