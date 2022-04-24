import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'utils/background_push.dart';
import 'utils/managers/client_manager.dart';
import 'utils/managers/theme_manager.dart';
import 'utils/platforms_info.dart';
import 'utils/sentry_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final clients = await ClientManager.getClients();
  Logs().level = kReleaseMode ? Level.warning : Level.verbose;

  if (PlatformInfos.isMobile) {
    BackgroundPush.clientOnly(clients.first);
  }

  runZonedGuarded(
    () => runApp(ChangeNotifierProvider<ThemeNotifier>(
        create: (_) => new ThemeNotifier(),
        child: Minestrix(clients: clients))),
    SentryController.captureException,
  );
}
