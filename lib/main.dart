import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:minestrix/app.dart';
import 'package:minestrix/global/Managers/ThemeManager.dart';
import 'package:minestrix/utils/platforms_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

/// Load database
Future<bool> loadHive() async {
  if (PlatformInfos.isBetaDesktop) {
    Hive.init((await getApplicationSupportDirectory()).path);
  } else {
    await Hive.initFlutter();
  }
  return true;
}

void main() {
  Logger.root.level = Level.ALL;
  runApp(ChangeNotifierProvider<ThemeNotifier>(
      create: (_) => new ThemeNotifier(),
      child: FutureBuilder(
          future: loadHive(),
          builder: (context, snap) {
            if (!snap.hasData)
              return MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 10),
                        Text("Loading database...")
                      ],
                    ),
                  ),
                ),
              );
            return Minestrix();
          })));
}
