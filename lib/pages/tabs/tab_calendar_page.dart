import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class TabCalendarPage extends StatelessWidget {
  const TabCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AutoRouter(inheritNavigatorObservers: true);
  }
}
