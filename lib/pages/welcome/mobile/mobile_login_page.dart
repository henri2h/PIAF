import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:piaf/chat/partials/login/login_card.dart';
import 'package:piaf/chat/utils/matrix_widget.dart';

@RoutePage()
class MobileLoginPage extends StatefulWidget {
  const MobileLoginPage({super.key, this.popOnLogin = false});

  final bool popOnLogin;

  @override
  State<MobileLoginPage> createState() => _MobileLoginPageState();
}

class _MobileLoginPageState extends State<MobileLoginPage> {
  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).getLoginClient();
    return Scaffold(
        appBar: AppBar(forceMaterialTransparency: true),
        body: ListView(children: [
          LoginMatrixCard(client: client, popOnLogin: widget.popOnLogin)
        ]));
  }
}
