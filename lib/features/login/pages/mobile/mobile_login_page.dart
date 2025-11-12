import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/features/login/widgets/login_card.dart';
import 'package:piaf/utils/matrix_widget.dart';

@RoutePage()
class MobileLoginPage extends StatefulWidget {
  const MobileLoginPage({super.key, this.popOnLogin = false});

  final bool popOnLogin;

  @override
  State<MobileLoginPage> createState() => _MobileLoginPageState();
}

class _MobileLoginPageState extends State<MobileLoginPage> {
  Future<Client>? futureClient;

  @override
  Widget build(BuildContext context) {
    futureClient ??= Matrix.of(context).getLoginClient();

    return FutureBuilder(
        future: futureClient,
        builder: (context, snap) {
          final client = snap.data;

          if (client == null) {
            return CircularProgressIndicator();
          }

          return Scaffold(
              appBar: AppBar(forceMaterialTransparency: true),
              body: ListView(children: [
                LoginMatrixCard(client: client, popOnLogin: widget.popOnLogin)
              ]));
        });
  }
}
