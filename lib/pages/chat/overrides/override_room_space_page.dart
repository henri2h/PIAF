import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/pages/chat_lib/space_page.dart';

@RoutePage()
class OverrideRoomSpacePage extends StatelessWidget {
  const OverrideRoomSpacePage(
      {super.key, required this.spaceId, required this.client, this.onBack});

  final String spaceId;
  final Client client;
  final void Function()? onBack;
  @override
  Widget build(BuildContext context) {
    return SpacePage(spaceId: spaceId, client: client, onBack: onBack);
  }
}
