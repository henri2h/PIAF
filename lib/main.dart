import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vodozemac/flutter_vodozemac.dart' as vod;
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';

import 'app.dart';
import 'utils/background_push.dart';
import 'utils/managers/client_manager.dart';
import 'utils/managers/theme_manager.dart';
import 'utils/platforms_info.dart';
import 'utils/settings.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  if (runWebViewTitleBarWidget(args)) {
    return;
  }

  await Settings().loadGuarded(); // load the settings

  await vod.init(wasmPath: './assets/assets/vodozemac/');

  final clients = await ClientManager.getClients();
  Logs().level = kReleaseMode ? Level.warning : Level.verbose;

  if (PlatformInfos.isMobile) {
    BackgroundPush.clientOnly(clients.first);
  }

  runMinestrix(clients);
}

void runMinestrix(List<Client> clients) {
  runApp(ChangeNotifierProvider<ThemeNotifier>(
      create: (_) => ThemeNotifier(), child: App(clients: clients)));
}
