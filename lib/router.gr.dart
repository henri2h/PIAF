// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i4;
import 'package:flutter/foundation.dart' as _i6;
import 'package:flutter/material.dart' as _i5;

import 'pages/home/homePage.dart' as _i1;
import 'pages/loginPage.dart' as _i2;
import 'pages/settingsPage.dart' as _i3;

class AppRouter extends _i4.RootStackRouter {
  AppRouter([_i5.GlobalKey<_i5.NavigatorState> navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i4.PageFactory> pagesMap = {
    HomeRoute.name: (routeData) {
      final args =
          routeData.argsAs<HomeRouteArgs>(orElse: () => const HomeRouteArgs());
      return _i4.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i1.HomePage(key: args.key, title: args.title));
    },
    LoginRoute.name: (routeData) {
      final args = routeData.argsAs<LoginRouteArgs>(
          orElse: () => const LoginRouteArgs());
      return _i4.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i2.LoginPage(key: args.key, title: args.title));
    },
    SettingsRoute.name: (routeData) {
      return _i4.MaterialPageX<dynamic>(
          routeData: routeData, child: _i3.SettingsPage());
    }
  };

  @override
  List<_i4.RouteConfig> get routes => [
        _i4.RouteConfig(HomeRoute.name, path: '/'),
        _i4.RouteConfig(LoginRoute.name, path: '/login-page'),
        _i4.RouteConfig(SettingsRoute.name, path: '/settings-page')
      ];
}

/// generated route for [_i1.HomePage]
class HomeRoute extends _i4.PageRouteInfo<HomeRouteArgs> {
  HomeRoute({_i6.Key key, String title})
      : super(name, path: '/', args: HomeRouteArgs(key: key, title: title));

  static const String name = 'HomeRoute';
}

class HomeRouteArgs {
  const HomeRouteArgs({this.key, this.title});

  final _i6.Key key;

  final String title;

  @override
  String toString() {
    return 'HomeRouteArgs{key: $key, title: $title}';
  }
}

/// generated route for [_i2.LoginPage]
class LoginRoute extends _i4.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({_i6.Key key, String title})
      : super(name,
            path: '/login-page', args: LoginRouteArgs(key: key, title: title));

  static const String name = 'LoginRoute';
}

class LoginRouteArgs {
  const LoginRouteArgs({this.key, this.title});

  final _i6.Key key;

  final String title;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, title: $title}';
  }
}

/// generated route for [_i3.SettingsPage]
class SettingsRoute extends _i4.PageRouteInfo<void> {
  const SettingsRoute() : super(name, path: '/settings-page');

  static const String name = 'SettingsRoute';
}
