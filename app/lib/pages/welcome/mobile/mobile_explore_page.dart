import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/login/login_button.dart';
import 'package:minestrix_chat/partials/login/matrix_server_chooser.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

@RoutePage()
class MobileExplorePage extends StatefulWidget {
  const MobileExplorePage({super.key});

  @override
  State<MobileExplorePage> createState() => _MobileExplorePageState();
}

class _MobileExplorePageState extends State<MobileExplorePage> {
  final domainController = MatrixServerChooserController();

  bool get passwordLogin => domainController.loginFlowsSupported
      .contains(AuthenticationTypes.password);

  Future<void> createAccount(Client client) async {
    const initialDeviceName = "MinesTRIX";
    const kind = AccountKind.guest;

    // domain has already been checked
    try {
      await client.register(
        initialDeviceDisplayName: initialDeviceName,
        kind: kind,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).getLoginClient();

    return Scaffold(
        appBar: AppBar(),
        body: Column(
          children: [
            MatrixServerChooser(
                controller: domainController,
                client: client,
                onChanged: (value) {
                  setState(() {});
                }),
            const SizedBox(height: 20),
            if (passwordLogin)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: LoginButton(
                    icon: Icons.explore,
                    onPressed: () async => await createAccount(client),
                    text: "Explore",
                    filled: true),
              )
          ],
        ));
  }
}
