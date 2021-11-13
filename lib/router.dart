// @CupertinoAutoRouter
// @AdaptiveAutoRouter
// @CustomAutoRouter
import 'package:auto_route/annotations.dart';
import 'package:minestrix/pages/home/homePage.dart';
import 'package:minestrix/pages/loginPage.dart';
import 'package:minestrix/pages/matrixLoadingPage.dart';
import 'package:minestrix/pages/settingsPage.dart';
import 'package:minestrix/routerAuthGuards.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    AutoRoute(page: MatrixLoadingPage, initial: true),
    AutoRoute(
      path: '/home',
      page: HomePage,
    ),
    AutoRoute(path: '/login', page: LoginPage),
    AutoRoute(path: '/settings', page: SettingsPage)
  ],
)
class $AppRouter {}
