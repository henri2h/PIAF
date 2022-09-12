import 'dart:async';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/settings.dart';
import 'package:minestrix_chat/utils/background_push.dart';
import 'package:minestrix_chat/utils/manager/client_manager.dart';
import 'package:minestrix_chat/utils/sentry_controller.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'utils/managers/theme_manager.dart';
import 'utils/platforms_info.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (runWebViewTitleBarWidget(args)) {
    return;
  }

  await Settings().loadGuarded(); // load the settings

  final clients = await ClientManager.getClients();
  Logs().level = kReleaseMode ? Level.warning : Level.verbose;

  if (PlatformInfos.isMobile) {
    BackgroundPush.clientOnly(clients.first);
  }

  // enable debug mode if needed
  if (!kDebugMode && await SentryController.getSentryStatus()) {
    SentryFlutter.init(
      (options) => {
        options.dsn =
            'https://c8621ef76fa54652b6766dd04761311a@o1215870.ingest.sentry.io/6357703',
        options.tracesSampleRate = 1.0,
      },
      appRunner: () => runMinestrix(clients),
    );
  } else {
    runMinestrix(clients);
  }
}

void runMinestrix(List<Client> clients) {
  runApp(ChangeNotifierProvider<ThemeNotifier>(
      create: (_) => ThemeNotifier(), child: Minestrix(clients: clients)));
}
