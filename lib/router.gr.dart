// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i5;
import 'package:flutter/material.dart' as _i6;

import 'pages/home/homePage.dart' as _i2;
import 'pages/loginPage.dart' as _i3;
import 'pages/matrixLoadingPage.dart' as _i1;
import 'pages/settingsPage.dart' as _i4;

class AppRouter extends _i5.RootStackRouter {
  AppRouter([_i6.GlobalKey<_i6.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i5.PageFactory> pagesMap = {
    MatrixLoadingRoute.name: (routeData) {
      return _i5.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i1.MatrixLoadingPage());
    },
    HomeRoute.name: (routeData) {
      final args =
          routeData.argsAs<HomeRouteArgs>(orElse: () => const HomeRouteArgs());
      return _i5.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i2.HomePage(key: args.key, title: args.title));
    },
    LoginRoute.name: (routeData) {
      final args = routeData.argsAs<LoginRouteArgs>(
          orElse: () => const LoginRouteArgs());
      return _i5.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i3.LoginPage(
              key: args.key, title: args.title, onLogin: args.onLogin));
    },
    SettingsRoute.name: (routeData) {
      return _i5.MaterialPageX<dynamic>(
          routeData: routeData, child: _i4.SettingsPage());
    }
  };

  @override
  List<_i5.RouteConfig> get routes => [
        _i5.RouteConfig(MatrixLoadingRoute.name, path: '/'),
        _i5.RouteConfig(HomeRoute.name, path: '/home'),
        _i5.RouteConfig(LoginRoute.name, path: '/login'),
        _i5.RouteConfig(SettingsRoute.name, path: '/settings')
      ];
}

/// generated route for [_i1.MatrixLoadingPage]
class MatrixLoadingRoute extends _i5.PageRouteInfo<void> {
  const MatrixLoadingRoute() : super(name, path: '/');

  static const String name = 'MatrixLoadingRoute';
}

/// generated route for [_i2.HomePage]
class HomeRoute extends _i5.PageRouteInfo<HomeRouteArgs> {
  HomeRoute({_i6.Key? key, String? title})
      : super(name, path: '/home', args: HomeRouteArgs(key: key, title: title));

  static const String name = 'HomeRoute';
}

class HomeRouteArgs {
  const HomeRouteArgs({this.key, this.title});

  final _i6.Key? key;

  final String? title;

  @override
  String toString() {
    return 'HomeRouteArgs{key: $key, title: $title}';
  }
}

/// generated route for [_i3.LoginPage]
class LoginRoute extends _i5.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({_i6.Key? key, String? title, dynamic Function(bool)? onLogin})
      : super(name,
            path: '/login',
            args: LoginRouteArgs(key: key, title: title, onLogin: onLogin));

  static const String name = 'LoginRoute';
}

class LoginRouteArgs {
  const LoginRouteArgs({this.key, this.title, this.onLogin});

  final _i6.Key? key;

  final String? title;

  final dynamic Function(bool)? onLogin;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, title: $title, onLogin: $onLogin}';
  }
}

/// generated route for [_i4.SettingsPage]
class SettingsRoute extends _i5.PageRouteInfo<void> {
  const SettingsRoute() : super(name, path: '/settings');

  static const String name = 'SettingsRoute';
}
