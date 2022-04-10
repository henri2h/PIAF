import 'package:flutter/material.dart';

import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'utils/managers/theme_manager.dart';

void main() {
  Logger.root.level = Level.ALL;
  runApp(ChangeNotifierProvider<ThemeNotifier>(
      create: (_) => new ThemeNotifier(), child: Minestrix()));
}
