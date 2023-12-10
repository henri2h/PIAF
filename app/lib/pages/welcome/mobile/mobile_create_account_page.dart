import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:minestrix_chat/partials/login/create_account_card.dart';

@RoutePage()
class MobileCreateAccountPage extends StatelessWidget {
  const MobileCreateAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(forceMaterialTransparency: true),
        body: const CreateAccountCard());
  }
}
