import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/login/login_button.dart';
import 'package:piaf/partials/login/matrix_server_chooser.dart';
import 'package:piaf/partials/utils/matrix_widget.dart';

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

  Future<void> createGuestAccount(Client client) async {
    const initialDeviceName = "PIAF";
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
        appBar: AppBar(forceMaterialTransparency: true),
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
                    onPressed: () async => await createGuestAccount(client),
                    text: "Explore",
                    filled: true),
              )
          ],
        ));
  }
}
