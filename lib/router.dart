// @CupertinoAutoRouter
// @AdaptiveAutoRouter
// @CustomAutoRouter
import 'package:auto_route/annotations.dart';
import 'package:minestrix/pages/home/homePage.dart';
import 'package:minestrix/pages/loginPage.dart';
import 'package:minestrix/pages/settingsPage.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    AutoRoute(page: HomePage, initial: true),
    AutoRoute(page: LoginPage),
    AutoRoute(page: SettingsPage)
  ],
)
class $AppRouter {}
