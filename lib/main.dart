import 'package:flutter/material.dart';

import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'package:minestrix/app.dart';
import 'package:minestrix/utils/Managers/ThemeManager.dart';

void main() {
  Logger.root.level = Level.ALL;
  runApp(ChangeNotifierProvider<ThemeNotifier>(
      create: (_) => new ThemeNotifier(), child: Minestrix()));
}
