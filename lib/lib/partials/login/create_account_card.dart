import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../../utils/matrix_widget.dart';
import 'login_button.dart';
import 'login_input.dart';
import 'matrix_server_chooser.dart';

class CreateAccountCard extends StatefulWidget {
  const CreateAccountCard({super.key});

  @override
  State<CreateAccountCard> createState() => _CreateAccountCardState();
}

class _CreateAccountCardState extends State<CreateAccountCard> {
  final TextEditingController _usernameController = TextEditingController(),
      _passwordController = TextEditingController();

  final domainController = MatrixServerChooserController();
  bool get passwordLogin => domainController.loginFlowsSupported
      .contains(AuthenticationTypes.password);

  String? _registerErrorText;

  Future<void> createAccount(Client client) async {
    const initialDeviceName = "MinesTRIX";
    const kind = AccountKind.user;

    if (_registerErrorText != null) {
      setState(() {
        _registerErrorText = null;
      });
    }

    // domain has already been checked
    try {
      await client.register(
        username: _usernameController.text,
        password: _passwordController.text,
        initialDeviceDisplayName: initialDeviceName,
        kind: kind,
      );
    } catch (err) {
      if (err is MatrixException) {
        // Handle flows

        final rawFlows = err.raw["flows"];

        String? type;
        // extract flow type
        if (rawFlows is List) {
          for (final flow in rawFlows) {
            if (flow is Map<String, dynamic>) {
              final stages = flow["stages"];
              if (stages is List) {
                for (final value in stages) {
                  if (value is String) type = value;
                }
              }
            }
          }
        }

        final session = err.raw["session"];

        if (session is String && type != null) {
          // Try again registering with this flow type.

          // We only support registration with password

          await client.register(
              username: _usernameController.text,
              password: _passwordController.text,
              initialDeviceDisplayName: initialDeviceName,
              kind: kind,
              auth: AuthenticationData(type: type, session: session));
        }
      }

      if (mounted) {
        setState(() {
          _registerErrorText = err.toString();
        });
      }
    }
  }

  bool _credentialsEdited = false;

  void onTextChanged() {
    final value = _usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty;
    if (_credentialsEdited != value && mounted) {
      setState(() {
        _credentialsEdited = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).getLoginClient();

    return Column(
      children: [
        MatrixServerChooser(
            controller: domainController,
            client: client,
            onChanged: (value) {
              setState(() {
                _passwordController.clear();
                _usernameController.clear();
              });
            }),
        if (passwordLogin)
          Row(
            children: [
              Flexible(
                child: LoginInput(
                    name: "username",
                    hintText: "@john.doe:example.com",
                    icon: Icons.account_circle,
                    tController: _usernameController,
                    onChanged: (_) => onTextChanged()),
              ),
            ],
          ),
        if (passwordLogin)
          LoginInput(
              name: "password",
              icon: Icons.lock_outline,
              tController: _passwordController,
              onChanged: (_) => onTextChanged(),
              obscureText: true),
        if (_registerErrorText != null)
          ListTile(
            title: Text("$_registerErrorText"),
            leading: const CircleAvatar(child: Icon(Icons.bug_report)),
          ),
        if (passwordLogin && _credentialsEdited)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: LoginButton(
                icon: Icons.login,
                onPressed: () async => await createAccount(client),
                text: "Create account",
                filled: true),
          ),
        FilledButton(
            onPressed: () async => await createAccount(client),
            child: Text("hey"))
      ],
    );
  }
}
