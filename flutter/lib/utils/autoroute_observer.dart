import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

class MyObserver extends AutoRouterObserver {
  final StreamController<String> controller;

  MyObserver(this.controller);

  @override
  void didPush(Route route, Route? previousRoute) {
    controller.add(route.settings.name ?? '');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    controller.add(route.settings.name ?? '');
  }
}
